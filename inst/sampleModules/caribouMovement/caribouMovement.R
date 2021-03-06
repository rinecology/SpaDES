usesSpaDESVersion <- "1.1.0"
if (packageVersion("SpaDES") < usesSpaDESVersion) {
  stop("This caribouMovement module was built with SpaDES version", usesSpaDESVersion,
       "Please update SpaDES to use this module")
}
rm(usesSpaDESVersion)

## module metadata
defineModule(sim, list(
  name = "caribouMovement",
  description = "Simulate caribou movement via correlated random walk.",
  keywords = c("caribou", "individual based movement model", "correlated random walk"),
  childModules = character(),
  authors = c(person(c("Eliot", "J", "B"), "McIntire",
                     email = "eliot.mcintire@canada.ca",
                     role = c("aut", "cre"))),
  version = numeric_version("1.1.0"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "month",
  citation = list(),
  documentation = list(),
  reqdPkgs = list("grid", "raster", "sp"),
  parameters = rbind(
    defineParameter("moveInitialTime", "numeric", start(sim)+1, NA, NA, "time to schedule first movement event"),
    defineParameter("moveInterval", "numeric", 1.0, NA, NA, "time interval between movoment events"),
    defineParameter("N", "numeric", 100L, 10L, 1000L, "initial number of caribou"),
    defineParameter("torus", "logical", FALSE, NA, NA, "should the map wrap around like a torus?"),
    defineParameter(".plotInitialTime", "numeric", start(sim), NA, NA, "time to schedule first plot event"),
    defineParameter(".plotInterval", "numeric", 1, NA, NA, "time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA_real_, NA, NA, "time to schedule first save event"),
    defineParameter(".saveInterval", "numeric", NA_real_, NA, NA, "time interval between save events")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = globals(sim)$stackName, objectClass = "RasterStack",
                 desc = "layername = \"habitatQuality\"", sourceURL = NA_character_)
  ),
  outputObjects = bind_rows(
    createsOutput(objectName = globals(sim)$stackName, objectClass = "RasterStack",
                  desc = "layername = \"habitatQuality\""),
    createsOutput(objectName = "caribou", objectClass = "SpatialPointsDataFrame",
                  desc = NA_character_)
  )
))

## event types
doEvent.caribouMovement <- function(sim, eventTime, eventType, debug = FALSE) {
  if (eventType == "init") {
    ### check for more detailed object dependencies:
    ### (use `checkObject` or similar)
    checkObject(sim, name = globals(sim)$stackName, layer = "habitatQuality")

    # do stuff for this event
    sim <- sim$caribouMovementInit(sim)

    # schedule the next event
    sim <- scheduleEvent(sim, P(sim)$moveInitialTime,
                         "caribouMovement", "move")
    #sim <- scheduleEvent(sim, P(sim)$moveInitialTime,
    #                     "caribouMovement", "move")
    sim <- scheduleEvent(sim, P(sim)$.plotInitialTime,
                         "caribouMovement", "plot.init", .last())
    sim <- scheduleEvent(sim, P(sim)$.saveInitialTime,
                         "caribouMovement", "save", .last()+1)
  } else if (eventType == "move") {
    # do stuff for this event
    sim <- sim$caribouMovementMove(sim)

    # schedule the next event
    sim <- scheduleEvent(sim, time(sim) +
                           P(sim)$moveInterval,
                         "caribouMovement", "move")
  } else if (eventType == "plot.init") {
    # do stuff for this event
    Plot(sim$caribou, addTo = paste("sim", globals(sim)$stackName,
                                    "habitatQuality", sep = "$"),
         new = FALSE, size = 0.2, pch = 19, gp = gpar(cex = 0.6))

    # schedule the next event
    sim <- scheduleEvent(sim, time(sim) +
                           P(sim)$.plotInterval,
                         "caribouMovement", "plot", .last())
  } else if (eventType == "plot") {
    # do stuff for this event
    Plot(sim$caribou, addTo = paste("sim", globals(sim)$stackName,
                                    "habitatQuality", sep = "$"),
         new = FALSE, pch = 19, size = 0.2, gp = gpar(cex = 0.6))
    Plot(sim$caribou, new = FALSE, pch = 19, size = 0.1, gp = gpar(cex = 0.6))

    # schedule the next event
    sim <- scheduleEvent(sim, time(sim) +
                           P(sim)$.plotInterval,
                         "caribouMovement", "plot", .last())
  } else if (eventType == "save") {
    # do stuff for this event
    sim <- saveFiles(sim)

    # schedule the next event
    sim <- scheduleEvent(sim, time(sim) +
                           P(sim)$.saveInterval,
                         "caribouMovement", "save", .last()+1)

  } else {
    warning(paste(
      "Undefined event type: \'", events(sim)[1, "eventType", with = FALSE],
      "\' in module \'", events(sim)[1,"moduleName", with = FALSE],"\'", sep = ""
    ))
  }
  return(invisible(sim))
}

## event functions
caribouMovementInit <- function(sim) {
  yrange <- c(ymin(sim[[globals(sim)$stackName]]),
              ymax(sim[[globals(sim)$stackName]]))
  xrange <- c(xmin(sim[[globals(sim)$stackName]]),
              xmax(sim[[globals(sim)$stackName]]))

  # initialize caribou agents
  N <- P(sim)$N
  IDs <- as.character(1:N)
  sex <- sample(c("female", "male"), N, replace=TRUE)
  age <- round(rnorm(N, mean=8, sd=3))
  x1 <- rep(0, N)
  y1 <- rep(0, N)
  starts <- cbind(x = runif(N, xrange[1],xrange[2]),
                  y = runif(N, yrange[1],yrange[2]))

  # create the caribou agent object
  sim$caribou <- SpatialPointsDataFrame(coords = starts,
                                        data = data.frame(x1, y1, sex, age))
  row.names(sim$caribou) <- IDs # alternatively, add IDs as column in data.frame above

  return(invisible(sim))
}

caribouMovementMove <- function(sim) {
  # crop any caribou that went off maps
  sim$caribou <- crop(sim$caribou, sim[[globals(sim)$stackName]])
  if (length(sim$caribou) == 0) stop("All agents are off map")

  # find out what pixels the individuals are on now
  ex <- sim[[globals(sim)$stackName]][["habitatQuality"]][sim$caribou]

  # step length is a function of current cell's habitat quality
  sl <- 0.25/ex

  ln <- rlnorm(length(ex), sl, 0.02) # log normal step length
  sd <- 30 # could be specified globally in params

  sim$caribou <- move("crw", agent = sim$caribou,
                      extent = extent(sim[[globals(sim)$stackName]]),
                      stepLength = ln, stddev = sd, lonlat = FALSE,
                      torus = P(sim)$torus)

  return(invisible(sim))
}
