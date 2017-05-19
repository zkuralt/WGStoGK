Tired of converting WGS coordinates to Gauss-Krüger one at a time?

This application will convert WGS84 coordinates (what you would encounter on say Google Maps or GPS devices) to Gauss-Krüger system. The latter is useful because units are in meters.

This application will enable you to batch convert coordinates with ease. You can copy data from your spreadsheet editor into the application. It will convert coordinates to GK upon click. You can also upload a batch file. It supports all three WGS84 coordinate notations (`dd°mm'ss.ss''`, `dd°mm.mmm'`, `dd.dddd°`). Right now the CRS in use is `+proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=bessel +towgs84=426.9,142.6,460.1,4.91,4.49,-12.42,17.1 +units=m +no_defs`.

![](workflow.jpg)

Future improvements:

 * custom or pre-defined coordinate reference system
 * import not only csv, but also other (spatial) formats like .gpx

Bug reports and improvements (pull requests) welcome in the Issue section.

Authors can be contacted through this portal or on Twitter [@zkuralt](https://twitter.com/zkuralt) and [@romunov](https://twitter.com/romunov).