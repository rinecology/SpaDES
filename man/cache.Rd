% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cache.R
\docType{methods}
\name{cache}
\alias{cache}
\alias{cache,ANY-method}
\alias{clearCache}
\alias{clearCache,ANY-method}
\alias{showCache}
\alias{showCache,ANY-method}
\title{Cache method for simList class objects}
\usage{
cache(cacheRepo = NULL, FUN, ..., notOlderThan = NULL)

\S4method{cache}{ANY}(cacheRepo = NULL, FUN, ..., notOlderThan = NULL)

clearCache(sim, afterDate, beforeDate, cacheRepo, ...)

\S4method{clearCache}{ANY}(sim, afterDate, beforeDate, cacheRepo, ...)

showCache(sim, cacheRepo, ...)

\S4method{showCache}{ANY}(sim, cacheRepo, ...)
}
\arguments{
\item{cacheRepo}{A repository used for storing cached objects.}

\item{FUN}{A function to be called.}

\item{...}{Other arguments passed to

If neither \code{afterDate} or \code{beforeDate} are provided, then all objects will be removed.
If both \code{afterDate} and \code{beforeDate} are specified, then all objects between \code{afterDate} and
\code{beforeDate} will be deleted.}

\item{notOlderThan}{load an artifact from the database only if it was created after notOlderThan.}

\item{sim}{A \code{simList} simulation object, generally produced by \code{simInit}.}

\item{afterDate}{Objects cached after this date will be deleted, formatted YYYY-MM-DD.}

\item{beforeDate}{Objects cached before this date will be deleted, formatted as YYYY-MM-DD.}
}
\value{
Identical to \code{\link[archivist]{cache}}

Will clear all objects from the \code{cachePath} of the sim object
}
\description{
Because the \code{simList} has an environment as one of its slots,
the caching mechanism of the archivist package does not work.
Here, we make a slight tweak to the \code{cache} function.
Specifically, we remove all elements that have an environment as part of
their attributes.
This is generally functions that are loaded from the modules,
but also the \code{.envir} slot in the \code{simList}.
Thus, only non-function objects are used as part of the \code{digest} call
in the \code{digest} package (used internally in the \code{cache} function).

\code{showCache} and \code{clearCache} are wrappers around \code{archivist} package
functions, specific to simList objects.
They allow the user a bit of control over what is being cached.
}
\details{
Normally, a user will access this functionality as an argument in \code{\link{spades}}.
}
\examples{
\dontrun{
mySim <- simInit(times=list(start=0.0, end=5.0),
                 params=list(.globals=list(stackName="landscape", burnStats = "testStats")),
                 modules=list("randomLandscapes", "fireSpread"),
                 paths=list(modulePath=system.file("sampleModules", package="SpaDES")))
if (require(archivist)) {
  # Call cache function directly
  archivist::createLocalRepo(paths(mySim)$cachePath)
  system.time(outSim <- cache(paths(mySim)$cachePath,
              spades, sim = copy(mySim), .plotInitialTime = NA, notOlderThan = Sys.time()))
  system.time(outSim <- cache(paths(mySim)$cachePath,
              spades, sim = copy(mySim), .plotInitialTime = NA))

  # This functionality can be achieved within a spades call
  # compare caching ... run once to create cache
  system.time(outSim <- spades(copy(mySim), cache = TRUE, notOlderThan = Sys.time(),
                               .plotInitialTime = NA))
  # compare... second time is fast
  system.time(outSimCached <- spades(copy(mySim), cache = TRUE, .plotInitialTime = NA))
  all.equal(outSim, outSimCached)
}
}

\dontrun{
clearCache(mySim)
}
\dontrun{
showCache(mySim)
}
}
\author{
Eliot McIntire

Eliot McIntire

Eliot McIntire
}
\seealso{
\code{\link[archivist]{cache}}.

\code{\link[archivist]{cache}}.

\code{\link[archivist]{splitTagsLocal}}.
}

