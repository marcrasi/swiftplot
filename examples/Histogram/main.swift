import SwiftPlot
import AGGRenderer
import SVGRenderer
import Foundation

var filePath = "examples/Reference/"
let fileName = "_20_histogram"

var x = [Float]()
var mean: Float = 100
var deviation: Float = 15

for _ in 1...1000 {
    let x1 = Float.random(in: 0.0...1.0)
    let x2 = Float.random(in: 0.0...1.0)
    let z1 = sqrt(-2 * log(x1))*cos(2*Float.pi*x2)
    // print("\(z1*deviation + mean)")
    x.append(z1*deviation + mean)
}

var agg_renderer = AGGRenderer()
var svg_renderer = SVGRenderer()

var histogram: Histogram = Histogram()
histogram.addSeries(data: x, bins: 50, label: "Plot 1", color: .blue)
histogram.plotTitle = PlotTitle("HISTOGRAM")
histogram.plotLabel = PlotLabel(xLabel: "X-AXIS", yLabel: "Y-AXIS")

histogram.drawGraphAndOutput(fileName: filePath+"agg/"+fileName, renderer: agg_renderer)
histogram.drawGraphAndOutput(fileName: filePath+"svg/"+fileName, renderer: svg_renderer)