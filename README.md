<!-- README.md is generated from README.Rmd. Please edit that file -->
graticule
=========

Graticules are the longitude latitude lines shown on a projected map, and defining and drawing these lines is not easy to automate. The graticule package provides the tools to create and draw these lines by explicit specification by the user. This provides a good compromise between high-level automation and the flexibility to drive the low level details as needed, using base graphics in R.

Installation
============

The graticule package is on GitHub, and can be installed like this:

    ```R
    if (packageVersion("devtools") < 1.6) {
      install.packages("devtools")
    }
    devtools::install_github("mdsumner/graticule")
    ```

Known issues
------------

o There's work needed for when `graticule_labels()` are created without using `xline/yline`, need more careful separation between generating every combination in the grid versus single lines

Examples
========

A simple example uses data from rworldmap to build a map around the state of Victoria in Australia. Victoria uses a local Lambert Conformal Conic projection that was introduced while the shift to GDA94 was implemented, to reduce complications due to working with more than one UTM zone for the state.

``` r
library(rgdal)
library(raster)
library(rworldmap)
data(countriesLow)
llproj <- projection(countriesLow)
library(graticule)
map<- subset(countriesLow, SOVEREIGNT == "Australia")

## VicGrid
prj <- "+proj=lcc +lat_1=-36 +lat_2=-38 +lat_0=-37 +lon_0=145 +x_0=2500000 +y_0=2500000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

pmap <- spTransform(map, CRS(prj))

## specify exactly where we want meridians and parallels
lons <- seq(140, 150, length = 5)
lats <- seq(-40, -35, length = 6)
## optionally, specify the extents of the meridians and parallels
## here we push them out a little on each side
xl <-  range(lons) + c(-0.4, 0.4)
yl <- range(lats) + c(-0.4, 0.4)
## build the lines with our precise locations and ranges
grat <- graticule(lons, lats, proj = prj, xlim = xl, ylim = yl)
## build the labels, here they sit exactly on the western and northern extent
## of our line ranges
labs <- graticule_labels(lons, lats, xline = min(xl), yline = max(yl), proj = prj)

## set up a map extent and plot
op <- par(mar = rep(0, 4))
plot(extent(grat) + c(4, 2) * 1e5, asp = 1, type = "n", axes = FALSE, xlab = "", ylab = "")
plot(pmap, add = TRUE)
## the lines are a SpatialLinesDataFrame
plot(grat, add = TRUE, lty = 5, col = rgb(0, 0, 0, 0.8))
## the labels are a SpatialPointsDataFrame, and islon tells us which kind
text(subset(labs, labs$islon), lab = parse(text = labs$lab[labs$islon]), pos = 3)
text(subset(labs, !labs$islon), lab = parse(text = labs$lab[!labs$islon]), pos = 2)
```

![](README-unnamed-chunk-2-1.png)

``` r
par(op)
```

A polar example
---------------

Download some sea ice concentration data and plot with a graticule. These passive microwave data are defined on a Polar Stereographic grid on the Hughes ellipsoid (predating WGS84), and there are daily files available since 1978. This is not the prettiest map, but the example is showing how we have control over exactly where the lines are created. We can build the lines anywhere, not necessarily at regular intervals or rounded numbers, and we can over or under extend the parallels relative to the meridians and vice versa.

``` r
library(raster)
library(graticule)
library(rgdal)
icefile <- "ftp://sidads.colorado.edu/pub/DATASETS/nsidc0051_gsfc_nasateam_seaice/final-gsfc/south/daily/2014/nt_20140320_f17_v01_s.bin"
tfile <- file.path(tempdir(), basename(icefile))
if (!file.exists(tfile)) download.file(icefile, tfile, mode = "wb")

ice <- raster(tfile)

meridians <- seq(-180, 160, by = 20)
parallels <- c(-80, -73.77, -68, -55, -45)
mlim <- c(-180, 180)
plim <- c(-88, -50)
grat <- graticule(lons = meridians, lats = parallels, xlim = mlim, ylim = plim, proj = projection(ice))
labs <- graticule_labels(meridians, parallels, xline = -45, yline = -60, proj = projection(ice))
plot(ice, axes = FALSE)
plot(grat, add = TRUE, lty = 3)
text(labs, lab = parse(text= labs$lab), col= c("firebrick", "darkblue")[labs$islon + 1], cex = 0.85)
title(sprintf("Sea ice concentration %s", gsub(".bin", "", basename(tfile))), cex.main = 0.8)
title(sub = projection(ice), cex.sub = 0.6)
```

![](README-unnamed-chunk-3-1.png)

Create the graticule as polygons
--------------------------------

Continuing from the sea ice example, build the graticule grid as actual polygons. Necessarily the `xlim/ylim` option is ignored since we have not specified sensibly closed polygonal rings where there are under or over laps.

``` r
polargrid <- graticule(lons = c(meridians, 180), lats = parallels,  proj = projection(ice), tiles = TRUE)
#> Loading required namespace: rgeos
centroids <- project(coordinates(polargrid), projection(ice), inv = TRUE)
labs <- graticule_labels(meridians, parallels,  proj = projection(ice))
labs <- graticule_labels(as.integer(centroids[,1]), as.integer(centroids[,2]),  proj = projection(ice))
labs <- labs[!duplicated(as.data.frame(labs)), ] ## this needs a fix
cols <- sample(colors(), nrow(polargrid))
op <- par(mar = rep(0, 4))
plot(polargrid, col  = cols, bg = "black")
text(labs[labs$islon, ], lab = parse(text = labs$lab[labs$islon]), col = "black",  cex = .55, pos = 3)
text(labs[!labs$islon, ], lab = parse(text = labs$lab[!labs$islon]), col = "black", cex = .55, pos = 1)
```

![](README-unnamed-chunk-4-1.png)

``` r
par(op)
```

Comparison to tools in sp and rgdal
-----------------------------------

The rgdal function `llgridlines()` will draw a graticule on a map but has a few limitations.

-   no control over the exact meridian and parallel lines to draw
-   the extent of lines is not independent of their perpendicular counterparts
-   relies on a projected object with sufficient verticular density.

Many of these limitations can be worked around, especially by leveraging tools in the raster package but it's not particularly elegant. Interestingly `mapGrid` in oce seems to share some of the same limitations, but I need to explore that more before being sure about the details.

Above we defined longitude and latitude ranges for an area of interest in Australia. We can plot the projected map and put on a `llgridlines` graticule. (Note that there's a fair region around the main land mass of Australia here, due to Heard Island, Macquarie Island and Lord Howe Island driving the bounds of this map.)

``` r
plot(pmap)
llgridlines(pmap)
```

![](README-unnamed-chunk-5-1.png)

We cannot easily modify the lines to be only in our local area, since `llgridlines` overrides our inputs with the bounding box of the overall object.

``` r
plot(pmap)
lons <- seq(140, 150, length = 5)
lats <- seq(-40, -35, length = 6)
llgridlines(pmap, easts = lons, norths = lats)
```

![](README-unnamed-chunk-6-1.png)

What we can do is crop the object, or create a new one with the overall extents of our region of interest. This is much closer to what I want but still I need to fiddle to get it just right.

``` r
op <- par(xpd = NA)
ex <- as(extent(range(lons), range(lats)), "SpatialPolygons")
projection(ex) <- llproj
pex <- spTransform(ex, CRS(projection(pmap)))
plot(extent(pex), type = "n", axes = FALSE, xlab = "", ylab = "", asp = 1)
plot(pmap, add = TRUE)
llgridlines(pex, easts = lons, norths = lats)
```

![](README-unnamed-chunk-7-1.png)

``` r
par(op)
```

How about the polar example? This is not bad, but the default number of vertices is not sufficient and we don't get a sensible set of meridians.

``` r
plot(ice, axes = FALSE)
##llgridlines(ice)  does not understand a raster
llgridlines(as(ice, "SpatialPoints"))
```

![](README-unnamed-chunk-8-1.png)

Try again, we increase the verticular density, but still I can't get a line at -180/180 and 80S.

``` r
plot(ice, axes = FALSE)
llgridlines(as(ice, "SpatialPoints"), easts = c(-180, -120, -60, 0, 60, 120), norths = c(-80, -70, -60, -50), ndiscr = 50)
```

![](README-unnamed-chunk-9-1.png)

Comparison to **mapGrid** in oce
--------------------------------

The oce package has a lot of really neat map projection tools, but it works rather differently from the *Spatial* and *raster* tools in R. We need to drive the creation of the plot from the start with `mapPlot`, as it sets up the projection metadata for the current plot and handles that for subsequent plotting additions. (My use of oce is inexpert, I'm not across much of the details yet so I may well be off-track with some things here).

Here is our map of Victoria.

``` r
library(oce)
## we need to hop the crevasse into another world
pp <- coordinates(as(as(map, "SpatialLines"), "SpatialPoints"))
mapPlot(pp[,1], pp[,2], projection = projection(pmap), longitudelim = xl, latitudelim = yl, type = "n", grid = FALSE)
mapGrid(longitude = lons, latitude = lats)
## and to prove that all is well in the world
plot(pmap, add = TRUE)
```

![](README-unnamed-chunk-10-1.png)

Here is our polar map, this is good I haven't explore oce enough yet to do it justice. For bonus points we add `mapTissot()`, which should be in the basic toolkit of all intrepid R mappers.

``` r
ipts <- coordinates(spTransform(xyFromCell(ice, sample(ncell(ice), 1000), spatial = TRUE), CRS(llproj)))
mapPlot(ipts[,1], ipts[,2], projection = projection(ice), type = "n", grid = FALSE)

plot(ice, add = TRUE)
mapGrid(10, 15)
mapTissot()
```

![](README-unnamed-chunk-11-1.png)

Also see here for another implementation of the Tissot Indicatrix in R by user [whuber on GIS StackExchange](http://gis.stackexchange.com/questions/31651/an-example-tissot-ellipse-for-an-equirectangular-projection).

Notes
-----

It should be said that efforts here should be shared with the sp and rgdal projects to improve the functionality for the `llgridlines` and its worker functions `gridlines` and `gridat` in that central place, and I agree with this. But I have an interest in working with graticules more directly as objects, and potentially stored in relational-table approach built on dplyr, and so I just found it simpler to start from scratch in this package. Also, there is a lot of this functionality spread around the place in sp, raster, maptools, fields, oce and many others. It is time for a new review, analogous to the effort that built sp in ca. 2002.

### Terminology

I tend to use the same terminology as used within [Manifold System](http://www.manifold.net) *because it's so awesome* and that's where I first learnt about most of these concepts. In my experience not many people use the term *graticule* in this way, so take it from the master himself on page 8 (Snyder, 1987):

> To identify the location of points on the Earth, a graticule or network of longitude and latitude lines has been superimposed on the surface. They are commonly referred to as meridians and parallels, respectively.

"Verticular density" is kind of a joke, but I like it. YMMV

References
----------

Snyder, John Parr. Map projections--A working manual. No. 1395. USGPO, 1987.

Environment
-----------

``` r
devtools::session_info()
#> Session info --------------------------------------------------------------
#>  setting  value                       
#>  version  R version 3.2.0 (2015-04-16)
#>  system   x86_64, linux-gnu           
#>  ui       X11                         
#>  language (EN)                        
#>  collate  en_US.UTF-8                 
#>  tz       <NA>
#> Packages ------------------------------------------------------------------
#>  package   * version date       source        
#>  curl        0.8     2015-06-06 CRAN (R 3.2.0)
#>  devtools    1.8.0   2015-05-09 CRAN (R 3.2.0)
#>  digest      0.6.8   2014-12-31 CRAN (R 3.2.0)
#>  evaluate    0.7     2015-04-21 CRAN (R 3.2.0)
#>  fields      8.2-1   2015-02-28 CRAN (R 3.2.0)
#>  foreign     0.8-63  2015-02-20 CRAN (R 3.1.2)
#>  formatR     1.2     2015-04-21 CRAN (R 3.2.0)
#>  git2r       0.10.1  2015-05-07 CRAN (R 3.2.0)
#>  graticule * 0.0.2   2015-06-07 local         
#>  gsw       * 1.0-3   2015-01-19 CRAN (R 3.2.0)
#>  htmltools   0.2.6   2014-09-08 CRAN (R 3.2.0)
#>  knitr       1.10.5  2015-05-06 CRAN (R 3.2.0)
#>  lattice     0.20-31 2015-03-30 CRAN (R 3.1.3)
#>  magrittr    1.5     2014-11-22 CRAN (R 3.2.0)
#>  maps        2.3-9   2014-09-22 CRAN (R 3.2.0)
#>  maptools    0.8-36  2015-04-24 CRAN (R 3.2.0)
#>  memoise     0.2.1   2014-04-22 CRAN (R 3.2.0)
#>  oce       * 0.9-17  2015-05-22 CRAN (R 3.2.0)
#>  raster    * 2.4-6   2015-06-01 local         
#>  Rcpp        0.11.6  2015-05-01 CRAN (R 3.2.0)
#>  rgdal     * 1.0-2   2015-06-06 local         
#>  rgeos       0.3-11  2015-05-29 CRAN (R 3.2.0)
#>  rmarkdown   0.6.1   2015-05-07 CRAN (R 3.2.0)
#>  rversions   1.0.1   2015-06-06 CRAN (R 3.2.0)
#>  rworldmap * 1.3-1   2013-12-12 CRAN (R 3.2.0)
#>  sp        * 1.1-1   2015-06-05 CRAN (R 3.2.0)
#>  spam        1.0-1   2014-09-09 CRAN (R 3.2.0)
#>  stringi     0.4-1   2014-12-14 CRAN (R 3.2.0)
#>  stringr     1.0.0   2015-04-30 CRAN (R 3.2.0)
#>  xml2        0.1.1   2015-06-02 CRAN (R 3.2.0)
#>  yaml        2.1.13  2014-06-12 CRAN (R 3.2.0)
```
