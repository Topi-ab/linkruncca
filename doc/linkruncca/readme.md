# LinkRunCCA - Connected Component Analysis RTL code

Linkruncca is a single pass connected component analysis framework capable of collecting statistics of 4- and 8-connected objects in raster scan 2D images.

![Alt text](linkruncca.drawio.svg)

The above example (white = background, no object there, non-white is foreground, object pixel) image consists of two objects. Linkruncca detects these objects, collects statistics on runtime, and sends the result per object out as soon as the whole object is processed.

User can customize the statistics to be collected, as long as the statistics is
- information per pixel, which is sent into the linkruncca with the binary pixel (foreground vs background).
- can be accumulated over one or more pixels.
E.g. bounding box, center of mass, min/max of hue/saturation/value, etc.

## 8- vs 4-connectivity

4-connectivity considers pixels sharing a borderline between them belonging to the same object (green pixels above are 4-connected to the red pixel, but yellow pixels are not).

8-connectivity considers pixels sharing a borderline, or a corner between belonging to the same object (green and yellow pixels above are 8-connected to the red pixel).

## Usage
Top level entity is vhdl_linkruncca[.vhdl]

### Configurable parameters
- imwidth => width of incoming image in pixels
- imheight => height of incoming image in pixels

### Interface signals
- clk => pixel clock input
- rst => active high reset input
- datavalid => valid input signal to state if pix_in is fed in during current clock cycle (AXI stream style)
- pix_in => pixel data input
- res_valid_out => output valid telling if res_data_out is valid during current clock cycle
- res_data_out => collected statistics objects

### User statistics

vhdl_linkruncca_pkg.vhdl describes the user defined statistics. User needs to define

**x_bits** and **y_bits**

These define the number of bits to represent unsigned x- and y-coordinates.

**linkruncca_collect_t**

This data structure collects information on per pixel basis. Everything which is to be collected to statistics, needs to be presented here as information for _this pixel_.

**linkruncca_feature_t**

This is the information collection data structure. This record holds all variables which are to be accumulated over single object in the image.

**linkruncca_feature_empty_val**

This function needs to return feature statistics which is empty (zero pixels accumulated to it). E.g. bounding box x_min value set to the highest possible number and x_max set to the smallest possible numer.

**linkruncca_feature_collect**

This function converts single pixel information (parameter a) to a feature statistics.

**linkruncca_feature_merge**

This function merges two statistics together and returns a single statistics.