% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pathos.R
\name{pathologicule}
\alias{pathologicule}
\title{Create a mesh of evenly spaced lines in another projection.}
\usage{
pathologicule(x, proj)
}
\arguments{
\item{x}{object to build line mesh for}

\item{proj}{the other projection}
}
\value{
spatial object
}
\description{
Create a mesh of evenly spaced lines in another projection.
}
\examples{
\dontrun{
library(maptools)
data(wrld_simpl)
library(raster)
w <- subset(wrld_simpl, NAME == "Australia")
plot(w)
laea <- pathologicule(w, "+proj=laea +lon_0=147 +lat_0=-42 +ellps=WGS84")
stere <- pathologicule(w, "+proj=stere +lon_0=147 +lat_0=-42 +ellps=WGS84")
plot(laea, add = TRUE, col = "dodgerblue")
plot(stere, add = TRUE, col = "firebrick")

stere <- "+proj=stere +lat_0=-90 +ellps=WGS84"
p <- spTransform(subset(wrld_simpl, coordinates(wrld_simpl)[,2] < -20), stere)
plot(extent(p) + 1e6, asp = 1, type = "n"); plot(p, add = TRUE)
laea <- pathologicule(p, "+proj=laea +lon_0=147 +lat_0=-72 +ellps=WGS84")
stere <- pathologicule(p, "+proj=stere +lon_0=147 +lat_0=-42 +ellps=WGS84")
plot(laea, add = TRUE, col = "dodgerblue")
plot(stere, add = TRUE, col = "firebrick")
}
}
