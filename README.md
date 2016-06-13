
<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Travis-CI Build Status](https://travis-ci.org/mdsumner/graticule.svg?branch=master)](https://travis-ci.org/mdsumner/graticule) [![](http://www.r-pkg.org/badges/version/graticule)](http://www.r-pkg.org/pkg/graticule) [![](http://cranlogs.r-pkg.org/badges/graticule)](http://www.r-pkg.org/pkg/graticule)

graticule
=========

Graticules are the longitude latitude lines shown on a projected map, and defining and drawing these lines is not easy to automate. The graticule package provides the tools to create and draw these lines by explicit specification by the user. This provides a good compromise between high-level automation and the flexibility to drive the low level details as needed, using base graphics in R.

Installation
============

Insall the latest released version from CRAN with

``` r
install.packages("graticule")
``

The development version of the graticule package is on GitHub, and can be installed like this:
```

``` r
devtools::install_github("mdsumner/graticule")
```

Known issues
------------

-   There's work needed for when `graticule_labels()` are created without using `xline/yline`, need more careful separation between generating every combination in the grid versus single lines
