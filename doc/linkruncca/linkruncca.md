# LinkRunCCA - Connected Component Analysis RTL code

Linkruncca is a single pass connected component analysis framework capable of collecting statistics of 4- and 8-connected objects in raster scan 2D images.

![Alt text](linkruncca.drawio.svg)

The above example (white = background, no object there, non-white is foreground, object pixel) image consists of two objects. Linkruncca detects these objects, collects statistics on runtime, and sends the result per object out as soon as the whole object is processed.

User can customize the statistics to be collected, as long as the statistics is
- information per pixel, which is sent into the linkruncca with the binary pixel (foreground vs background).
- can be accumulated over one ore more pixels.
E.g. bounding box, center of mass, min/max of hue/saturation/value, etc.

Top level entity is vhdl_linkruncca[.vhdl]