import Foundation

// class defining a barGraph and all it's logic
public class Histogram<T:FloatConvertible>: Plot {

    let MAX_DIV: Float = 50

    public var xOffset: Float = 0
    public var yOffset: Float = 0

    public var plotTitle: PlotTitle? = nil
    public var plotLabel: PlotLabel? = nil
    public var plotLegend: PlotLegend = PlotLegend()
    public var plotBorder: PlotBorder = PlotBorder()
    public var plotDimensions: PlotDimensions {
        willSet{
            plotBorder.topLeft       = Point(newValue.subWidth*0.1, newValue.subHeight*0.9)
            plotBorder.topRight      = Point(newValue.subWidth*0.9, newValue.subHeight*0.9)
            plotBorder.bottomLeft    = Point(newValue.subWidth*0.1, newValue.subHeight*0.1)
            plotBorder.bottomRight   = Point(newValue.subWidth*0.9, newValue.subHeight*0.1)
            plotLegend.legendTopLeft = Point(plotBorder.topLeft.x + Float(20), plotBorder.topLeft.y - Float(20))
        }
    }
    public var strokeWidth: Float = 2
    public var enableGrid = true
    public var gridLineThickness: Float = 0.5
    public var gridColor: Color = .gray

    var scaleY: Float = 1
    var scaleX: Float = 1
    var plotMarkers: PlotMarkers = PlotMarkers()
    var histogramSeries = HistogramSeries<T>()
    var histogramStackSeries = [HistogramSeries<T>]()
    var barWidth: Float = 0
    var xMargin: Float = 5
    var isNormalized = false
    var origin = zeroPoint

    public init(width: Float = 1000,
                height: Float = 660,
                isNormalized: Bool = false,
                enableGrid: Bool = false){
        plotDimensions = PlotDimensions(frameWidth: width, frameHeight: height)
        self.isNormalized = isNormalized
        self.enableGrid = enableGrid
    }
    public func addSeries(_ s: HistogramSeries<T>){
        histogramSeries = s
    }
    public func addSeries(data: [T],
                          bins: Int,
                          label: String,
                          color: Color = .lightBlue,
                          histogramType: HistogramSeriesOptions.HistogramType = .bar){
        addSeries(calculateSeriesData(data: data,
                                      bins: bins,
                                      label: label,
                                      color: color,
                                      histogramType: histogramType))
    }
    public func addStackSeries(data: [T],
                               label: String,
                               color: Color = .lightBlue){
        histogramStackSeries.append(calculateSeriesData(data: data,
                                                        bins: histogramSeries.bins,
                                                        label: label,
                                                        color: color,
                                                        histogramType: histogramSeries.histogramSeriesOptions.histogramType))
    }
    func calculateSeriesData(data: [T],
                             bins: Int,
                             label: String,
                             color: Color,
                             histogramType: HistogramSeriesOptions.HistogramType) -> HistogramSeries<T> {

        var minimumElement = data[0]
        var maximumElement = data[0]
        for index in 1..<data.count {
            if (data[index]>maximumElement) {
                maximumElement = data[index]
            }
            if(data[index]<minimumElement) {
                minimumElement = data[index]
            }
        }
        let minimumX = T(roundFloor10(Float(minimumElement)))
        let maximumX = T(roundCeil10(Float(maximumElement)))
        let binInterval = (maximumX-minimumX)/T(bins)
        var dataIndex: Int = 0
        var binStart = minimumX
        var binEnd = minimumX + binInterval
        var maximumFrequency: Float = 0
        var binFrequency = [Float](repeating: 0, count: bins)

        for index in 0..<data.count {
            let binIndex = Int(Float(data[index] - minimumElement)/Float(binInterval))
            if(binIndex < binFrequency.count) {
                binFrequency[binIndex]+=1;
                if(binFrequency[binIndex] > maximumFrequency) {
                    maximumFrequency = binFrequency[binIndex]
                }
            }
            else {
                binFrequency[binIndex-1]+=1;
                if(binFrequency[binIndex-1] > maximumFrequency) {
                    maximumFrequency = binFrequency[binIndex-1]
                }
            }
        }
        if (isNormalized) {
            let factor = Float(data.count)*Float(binInterval)
            for index in 0..<bins {
                binFrequency[index]/=factor
            }
            maximumFrequency/=factor
        }
        return HistogramSeries<T>(data: data,
                                  bins: bins,
                                  isNormalized: isNormalized,
                                  label: label,
                                  color: color,
                                  histogramType: histogramType,
                                  binFrequency: binFrequency,
                                  maximumFrequency: maximumFrequency,
                                  minimumX: minimumX,
                                  maximumX: maximumX,
                                  minimumElement: minimumElement,
                                  maximumElement: maximumElement,
                                  binInterval: binInterval)
    }
    func recalculateBins(series: HistogramSeries<T>,
                         binStart: T,
                         binEnd: T,
                         binInterval: T) {
        series.binFrequency.removeAll()
        series.maximumFrequency = 0
        series.bins = Int(Float(binEnd - binStart)/Float(binInterval))
        series.binFrequency = [Float](repeating: 0, count: series.bins)
        series.binInterval = binInterval
        // for start in stride(from: Float(binStart), through: Float(binEnd), by: Float(binInterval)){
        //     let end = start + Float(binInterval)
        //     var count: Float = 0
        //     for d in series.data {
        //         if(d < T(end) && d >= T(start)) {
        //             count += 1
        //         }
        //     }
        //     if (count > series.maximumFrequency) {
        //         series.maximumFrequency = count
        //     }
        //     series.binFrequency.append(count)
        // }
        for index in 0..<series.data.count {
            let binIndex = Int(Float(series.data[index] - series.minimumElement!)/Float(binInterval))
            if(binIndex < series.binFrequency.count) {
                series.binFrequency[binIndex]+=1;
                if(series.binFrequency[binIndex] > series.maximumFrequency) {
                    series.maximumFrequency = series.binFrequency[binIndex]
                }
            }
            else {
                series.binFrequency[binIndex-1]+=1;
                if(series.binFrequency[binIndex-1] > series.maximumFrequency) {
                    series.maximumFrequency = series.binFrequency[binIndex-1]
                }
            }
        }
        if (isNormalized) {
            let factor = Float(series.data.count)*Float(binInterval)
            for index in 0..<series.bins {
                series.binFrequency[index]/=factor
            }
            series.maximumFrequency/=factor
        }
    }
}

// extension containing drawing logic
extension Histogram {

    // call functions to draw the graph
    public func drawGraphAndOutput(fileName name: String = "swift_plot_histogram", renderer: Renderer){
        renderer.xOffset = xOffset
        renderer.yOffset = yOffset
        renderer.plotDimensions = plotDimensions
        plotBorder.topLeft       = Point(plotDimensions.subWidth*0.1, plotDimensions.subHeight*0.9)
        plotBorder.topRight      = Point(plotDimensions.subWidth*0.9, plotDimensions.subHeight*0.9)
        plotBorder.bottomLeft    = Point(plotDimensions.subWidth*0.1, plotDimensions.subHeight*0.1)
        plotBorder.bottomRight   = Point(plotDimensions.subWidth*0.9, plotDimensions.subHeight*0.1)
        plotLegend.legendTopLeft = Point(plotBorder.topLeft.x + Float(20), plotBorder.topLeft.y - Float(20))
        calcLabelLocations(renderer: renderer)
        calcMarkerLocAndScalePts(renderer: renderer)
        drawGrid(renderer: renderer)
        drawBorder(renderer: renderer)
        drawMarkers(renderer: renderer)
        drawPlots(renderer: renderer)
        drawTitle(renderer: renderer)
        drawLabels(renderer: renderer)
        drawLegends(renderer: renderer)
        saveImage(fileName: name, renderer: renderer)
    }

    public func drawGraph(renderer: Renderer){
        renderer.xOffset = xOffset
        renderer.yOffset = yOffset
        plotBorder.topLeft       = Point(plotDimensions.subWidth*0.1, plotDimensions.subHeight*0.9)
        plotBorder.topRight      = Point(plotDimensions.subWidth*0.9, plotDimensions.subHeight*0.9)
        plotBorder.bottomLeft    = Point(plotDimensions.subWidth*0.1, plotDimensions.subHeight*0.1)
        plotBorder.bottomRight   = Point(plotDimensions.subWidth*0.9, plotDimensions.subHeight*0.1)
        plotLegend.legendTopLeft = Point(plotBorder.topLeft.x + Float(20), plotBorder.topLeft.y - Float(20))
        calcLabelLocations(renderer: renderer)
        calcMarkerLocAndScalePts(renderer: renderer)
        drawGrid(renderer: renderer)
        drawBorder(renderer: renderer)
        drawMarkers(renderer: renderer)
        drawPlots(renderer: renderer)
        drawTitle(renderer: renderer)
        drawLabels(renderer: renderer)
        drawLegends(renderer: renderer)
    }

    public func drawGraphOutput(fileName name: String = "swift_plot_histogram", renderer: Renderer){
        renderer.plotDimensions = plotDimensions
        renderer.drawOutput(fileName: name)
    }

    // functions implementing plotting logic
    func calcLabelLocations(renderer: Renderer){
        if (plotLabel != nil) {
            let xWidth: Float = renderer.getTextWidth(text: plotLabel!.xLabel,
                                                      textSize: plotLabel!.labelSize)
            let yWidth: Float = renderer.getTextWidth(text: plotLabel!.yLabel,
                                                      textSize: plotLabel!.labelSize)
            plotLabel!.xLabelLocation = Point(((plotBorder.bottomRight.x + plotBorder.bottomLeft.x)*Float(0.5)) - xWidth*Float(0.5),
                                              plotBorder.bottomLeft.y - plotLabel!.labelSize - 0.05*plotDimensions.graphHeight)
            plotLabel!.yLabelLocation = Point((plotBorder.bottomLeft.x - plotLabel!.labelSize - 0.05*plotDimensions.graphWidth),
                                              ((plotBorder.bottomLeft.y + plotBorder.topLeft.y)*Float(0.5) - yWidth))
        }
        if (plotTitle != nil) {
            let titleWidth: Float = renderer.getTextWidth(text: plotTitle!.title,
                                                          textSize: plotTitle!.titleSize)
            plotTitle!.titleLocation = Point(((plotBorder.topRight.x + plotBorder.topLeft.x)*Float(0.5)) - titleWidth*Float(0.5),
                                             plotBorder.topLeft.y + plotTitle!.titleSize*Float(0.5))
        }
    }

    func calcMarkerLocAndScalePts(renderer: Renderer){

        var maximumY = Float(histogramSeries.maximumFrequency)
        let minimumY = Float(0)
        var maximumX: T = histogramSeries.maximumX!
        var minimumX: T = histogramSeries.minimumX!

        for series in histogramStackSeries {
            if (series.maximumX! > maximumX) {
                maximumX = series.maximumX!
            }
            if (series.minimumX! < minimumX) {
                minimumX = series.minimumX!
            }
        }
        let binInterval = (maximumX-minimumX)/T(histogramSeries.bins)
        recalculateBins(series: histogramSeries,
                        binStart: minimumX,
                        binEnd: maximumX,
                        binInterval: binInterval)
        for index in 0..<histogramStackSeries.count {
            recalculateBins(series: histogramStackSeries[index],
                            binStart: minimumX,
                            binEnd: maximumX,
                            binInterval: binInterval)
        }
        for index in 0..<histogramSeries.bins {
            var tempFrequency = histogramSeries.binFrequency[index]
            for series in histogramStackSeries {
                tempFrequency += series.binFrequency[index]
            }
            if (tempFrequency>maximumY) {
                maximumY = tempFrequency
            }
        }

        barWidth = round((plotDimensions.graphWidth - Float(2.0*xMargin))/Float(histogramSeries.bins))

        plotMarkers.xMarkers = [Point]()
        plotMarkers.yMarkers = [Point]()
        plotMarkers.xMarkersTextLocation = [Point]()
        plotMarkers.yMarkersTextLocation = [Point]()
        plotMarkers.xMarkersText = [String]()
        plotMarkers.xMarkersText = [String]()

        origin = Point((plotDimensions.graphWidth-(2.0*xMargin))/Float(maximumX-minimumX)*Float(T(-1)*minimumX), 0.0)

        let topScaleMargin: Float = (plotDimensions.subHeight - plotDimensions.graphHeight)*Float(0.5) - 10.0
        scaleY = Float(maximumY - minimumY) / (plotDimensions.graphHeight - topScaleMargin)
        scaleX = Float(maximumX - minimumX) / (plotDimensions.graphWidth-Float(2.0*xMargin))
        let nD1: Int = max(getNumberOfDigits(Float(maximumY)), getNumberOfDigits(Float(minimumY)))
        var v1: Float
        if (nD1 > 1 && maximumY <= pow(Float(10), Float(nD1 - 1))) {
            v1 = Float(pow(Float(10), Float(nD1 - 2)))
        } else if (nD1 > 1) {
            v1 = Float(pow(Float(10), Float(nD1 - 1)))
        } else {
            v1 = Float(pow(Float(10), Float(0)))
        }

        let nY: Float = v1/scaleY
        var inc1: Float = nY
        if(plotDimensions.graphHeight/nY > MAX_DIV){
            inc1 = (plotDimensions.graphHeight/nY)*inc1/MAX_DIV
        }

        var yM: Float = origin.y
        while yM<=plotDimensions.graphHeight {
            if(yM+inc1<0.0 || yM<0.0){
                yM = yM + inc1
                continue
            }
            let p: Point = Point(0, yM)
            plotMarkers.yMarkers.append(p)
            let text_p: Point = Point(-(renderer.getTextWidth(text: "\(round(scaleY*(yM-origin.y)))", textSize: plotMarkers.markerTextSize)+8), yM - 4)
            plotMarkers.yMarkersTextLocation.append(text_p)
            plotMarkers.yMarkersText.append("\(round(scaleY*(yM-origin.y)))")
            yM = yM + inc1
        }

        let xRange = niceRoundFloor(Float(maximumX - minimumX))
        let nD2: Int = getNumberOfDigits(xRange)
        var v2: Float
        if (nD2 > 1 && xRange <= pow(Float(10), Float(nD2 - 1))) {
            v2 = Float(pow(Float(10), Float(nD2 - 2)))
        } else if (nD2 > 1) {
            v2 = Float(pow(Float(10), Float(nD2 - 1)))
        } else {
            v2 = Float(pow(Float(10), Float(0)))
        }

        let nX: Float = v2/scaleX
        var inc2: Float = nX
        if(plotDimensions.graphWidth/nX > MAX_DIV){
            inc2 = (plotDimensions.graphHeight/nY)*inc1/MAX_DIV
        }
        let xM: Float = xMargin
        let scaleXInv = 1.0/scaleX
        let xIncrement = inc2*scaleX
        for i in stride(from: Float(minimumX), through: Float(maximumX), by: xIncrement)  {
            let p: Point = Point((i-Float(minimumX))*scaleXInv + xM , 0)
            plotMarkers.xMarkers.append(p)
            let textWidth: Float = renderer.getTextWidth(text: "\(i)", textSize: plotMarkers.markerTextSize)
            let text_p: Point = Point((i - Float(minimumX))*scaleXInv - textWidth/Float(2), -2.0*plotMarkers.markerTextSize)
            plotMarkers.xMarkersTextLocation.append(text_p)
            plotMarkers.xMarkersText.append("\(i)")
        }

        // scale points to be plotted according to plot size
        let scaleYInv: Float = 1.0/scaleY
        histogramSeries.scaledBinFrequency.removeAll();
        for j in 0..<histogramSeries.binFrequency.count {
            let frequency = Float(histogramSeries.binFrequency[j])
            histogramSeries.scaledBinFrequency.append(frequency*scaleYInv + origin.y)
        }
        for index in 0..<histogramStackSeries.count {
            for j in 0..<histogramStackSeries[index].binFrequency.count {
                let frequency = Float(histogramStackSeries[index].binFrequency[j])
                histogramStackSeries[index].scaledBinFrequency.append(frequency*scaleYInv + origin.y)
            }
        }
    }

    //functions to draw the plot
    func drawBorder(renderer: Renderer){
        renderer.drawRect(topLeftPoint: plotBorder.topLeft,
                          topRightPoint: plotBorder.topRight,
                          bottomRightPoint: plotBorder.bottomRight,
                          bottomLeftPoint: plotBorder.bottomLeft,
                          strokeWidth: plotBorder.borderThickness,
                          strokeColor: Color.black, isOriginShifted: false)
    }

    func drawGrid(renderer: Renderer) {
        if (enableGrid) {
            for index in 0..<plotMarkers.xMarkers.count {
                let p1 = Point(plotMarkers.xMarkers[index].x, 0)
                let p2 = Point(plotMarkers.xMarkers[index].x, plotDimensions.graphHeight)
                renderer.drawLine(startPoint: p1,
                                  endPoint: p2,
                                  strokeWidth: gridLineThickness,
                                  strokeColor: gridColor,
                                  isDashed: false,
                                  isOriginShifted: true)
            }
            for index in 0..<plotMarkers.yMarkers.count {
                let p1 = Point(0, plotMarkers.yMarkers[index].y)
                let p2 = Point(plotDimensions.graphWidth, plotMarkers.yMarkers[index].y)
                renderer.drawLine(startPoint: p1,
                                  endPoint: p2,
                                  strokeWidth: gridLineThickness,
                                  strokeColor: gridColor,
                                  isDashed: false,
                                  isOriginShifted: true)
            }
        }
    }

    func drawMarkers(renderer: Renderer) {
        for index in 0..<plotMarkers.xMarkers.count {
            let p1: Point = Point(plotMarkers.xMarkers[index].x, -6)
            let p2: Point = Point(plotMarkers.xMarkers[index].x, 0)
            renderer.drawLine(startPoint: p1,
                              endPoint: p2,
                              strokeWidth: plotBorder.borderThickness,
                              strokeColor: Color.black,
                              isDashed: false,
                              isOriginShifted: true)
            renderer.drawText(text: plotMarkers.xMarkersText[index],
                              location: plotMarkers.xMarkersTextLocation[index],
                              textSize: plotMarkers.markerTextSize,
                              strokeWidth: 0.7,
                              angle: 0,
                              isOriginShifted: true)
        }

        for index in 0..<plotMarkers.yMarkers.count {
            let p1: Point = Point(-6, plotMarkers.yMarkers[index].y)
            let p2: Point = Point(0, plotMarkers.yMarkers[index].y)
            renderer.drawLine(startPoint: p1,
                              endPoint: p2,
                              strokeWidth: plotBorder.borderThickness,
                              strokeColor: Color.black,
                              isDashed: false,
                              isOriginShifted: true)
            renderer.drawText(text: plotMarkers.yMarkersText[index],
                              location: plotMarkers.yMarkersTextLocation[index],
                              textSize: plotMarkers.markerTextSize,
                              strokeWidth: 0.7,
                              angle: 0,
                              isOriginShifted: true)
        }

    }

    func drawPlots(renderer: Renderer) {
        var xM = Float(xMargin)
        switch histogramSeries.histogramSeriesOptions.histogramType {
        case .bar:
            for i in 0..<histogramSeries.bins {
                var currentHeight: Float = histogramSeries.scaledBinFrequency[i]
                var bL = Point(xM,0.0)
                var bR = Point(xM+barWidth,0.0)
                var tL = Point(xM,currentHeight)
                var tR = Point(xM+barWidth,currentHeight)
                renderer.drawSolidRect(topLeftPoint: tL,
                                       topRightPoint: tR,
                                       bottomRightPoint: bR,
                                       bottomLeftPoint: bL,
                                       fillColor: histogramSeries.color,
                                       hatchPattern: .none,
                                       isOriginShifted: true)

                for series in histogramStackSeries {
                    bL = Point(bL.x, currentHeight)
                    bR = Point(bR.x, currentHeight)
                    tL = Point(tL.x, bL.y + series.scaledBinFrequency[i])
                    tR = Point(tR.x, bR.y + series.scaledBinFrequency[i])
                    renderer.drawSolidRect(topLeftPoint: tL,
                                           topRightPoint: tR,
                                           bottomRightPoint: bR,
                                           bottomLeftPoint: bL,
                                           fillColor: series.color,
                                           hatchPattern: .none,
                                           isOriginShifted: true)
                    currentHeight += series.scaledBinFrequency[i]
                }
                xM+=barWidth
            }
        case .step:
            var firstHeight: Float = histogramSeries.scaledBinFrequency[0]
            var firstBottomLeft = Point(xM, 0.0)
            var firstTopLeft    = Point(xM, firstHeight)
            renderer.drawLine(startPoint: firstBottomLeft,
                              endPoint: firstTopLeft,
                              strokeWidth: strokeWidth,
                              strokeColor: histogramSeries.color,
                              isDashed: false,
                              isOriginShifted: true)
            for series in histogramStackSeries {
                firstBottomLeft = Point(firstBottomLeft.x, firstHeight)
                firstTopLeft = Point(firstTopLeft.x, firstHeight + series.scaledBinFrequency[0])
                renderer.drawLine(startPoint: firstBottomLeft,
                                  endPoint: firstTopLeft,
                                  strokeWidth: strokeWidth,
                                  strokeColor: series.color,
                                  isDashed: false,
                                  isOriginShifted: true)
                firstHeight += series.scaledBinFrequency[0]
            }
            for i in 0..<histogramSeries.bins {
                var currentHeight: Float = histogramSeries.scaledBinFrequency[i]
                var topLeft = Point(xM,currentHeight)
                var topRight = Point(xM+barWidth,currentHeight)
                renderer.drawLine(startPoint: topLeft,
                                  endPoint: topRight,
                                  strokeWidth: strokeWidth,
                                  strokeColor: histogramSeries.color,
                                  isDashed: false,
                                  isOriginShifted: true)
                if (i != histogramSeries.bins-1) {
                    let nextTopLeft = Point(topRight.x, histogramSeries.scaledBinFrequency[i+1])
                    renderer.drawLine(startPoint: topRight,
                                      endPoint: nextTopLeft,
                                      strokeWidth: strokeWidth,
                                      strokeColor: histogramSeries.color,
                                      isDashed: false,
                                      isOriginShifted: true)
                }
                for series in histogramStackSeries {
                    topLeft = Point(topLeft.x, currentHeight + series.scaledBinFrequency[i])
                    topRight = Point(topRight.x, currentHeight + series.scaledBinFrequency[i])
                    if (series.scaledBinFrequency[i] > 0) {
                        renderer.drawLine(startPoint: topLeft,
                                          endPoint: topRight,
                                          strokeWidth: strokeWidth,
                                          strokeColor: series.color,
                                          isDashed: false,
                                          isOriginShifted: true)
                        if (i != histogramSeries.bins-1) {
                            var nextHeight = histogramSeries.scaledBinFrequency[i+1]
                            for k in histogramStackSeries {
                                nextHeight += k.scaledBinFrequency[i+1]
                            }
                            let nextTopLeft = Point(topRight.x, nextHeight)
                            renderer.drawLine(startPoint: topRight,
                                              endPoint: nextTopLeft,
                                              strokeWidth: strokeWidth,
                                              strokeColor: series.color,
                                              isDashed: false,
                                              isOriginShifted: true)
                        }
                    }
                    currentHeight += series.scaledBinFrequency[i]
                }
                xM+=barWidth
            }
            var lastHeight: Float = histogramSeries.scaledBinFrequency[histogramSeries.scaledBinFrequency.count-1]
            var lastBottomRight = Point(xM, 0.0)
            var lastTopRight    = Point(xM, lastHeight)
            renderer.drawLine(startPoint: lastBottomRight,
                              endPoint: lastTopRight,
                              strokeWidth: strokeWidth,
                              strokeColor: histogramSeries.color,
                              isDashed: false,
                              isOriginShifted: true)
            for series in histogramStackSeries {
                lastBottomRight = Point(lastBottomRight.x, lastHeight)
                lastTopRight = Point(lastTopRight.x, lastHeight + series.scaledBinFrequency[series.scaledBinFrequency.count-1])
                renderer.drawLine(startPoint: lastBottomRight,
                                  endPoint: lastTopRight,
                                  strokeWidth: strokeWidth,
                                  strokeColor: series.color,
                                  isDashed: false,
                                  isOriginShifted: true)
                lastHeight += series.scaledBinFrequency[series.scaledBinFrequency.count-1]
            }
        }
    }

    func drawTitle(renderer: Renderer) {
        guard let plotTitle = self.plotTitle else { return }
        renderer.drawText(text: plotTitle.title,
                          location: plotTitle.titleLocation,
                          textSize: plotTitle.titleSize,
                          strokeWidth: 1.2,
                          angle: 0,
                          isOriginShifted: false)
    }

    func drawLabels(renderer: Renderer) {
        guard let plotLabel = self.plotLabel else { return }
        renderer.drawText(text: plotLabel.xLabel,
                          location: plotLabel.xLabelLocation,
                          textSize: plotLabel.labelSize,
                          strokeWidth: 1.2,
                          angle: 0,
                          isOriginShifted: false)
        renderer.drawText(text: plotLabel.yLabel,
                          location: plotLabel.yLabelLocation,
                          textSize: plotLabel.labelSize,
                          strokeWidth: 1.2,
                          angle: 90,
                          isOriginShifted: false)
    }

    func drawLegends(renderer: Renderer) {
        var maxWidth: Float = 0
        var legendSeries = histogramStackSeries
        legendSeries.insert(histogramSeries, at: 0)
        for s in legendSeries {
            let w = renderer.getTextWidth(text: s.label, textSize: plotLegend.legendTextSize)
            if (w > maxWidth) {
                maxWidth = w
            }
        }
        plotLegend.legendWidth  = maxWidth + 3.5*plotLegend.legendTextSize
        plotLegend.legendHeight = (Float(histogramStackSeries.count + 1)*2.0 + 1.0)*plotLegend.legendTextSize

        let p1: Point = Point(plotLegend.legendTopLeft.x, plotLegend.legendTopLeft.y)
        let p2: Point = Point(plotLegend.legendTopLeft.x + plotLegend.legendWidth, plotLegend.legendTopLeft.y)
        let p3: Point = Point(plotLegend.legendTopLeft.x + plotLegend.legendWidth, plotLegend.legendTopLeft.y - plotLegend.legendHeight)
        let p4: Point = Point(plotLegend.legendTopLeft.x, plotLegend.legendTopLeft.y - plotLegend.legendHeight)

        renderer.drawSolidRectWithBorder(topLeftPoint: p1,
                                         topRightPoint: p2,
                                         bottomRightPoint: p3,
                                         bottomLeftPoint: p4,
                                         strokeWidth: plotBorder.borderThickness,
                                         fillColor: Color.transluscentWhite,
                                         borderColor: Color.black,
                                         isOriginShifted: false)

        for i in 0..<legendSeries.count {
            let tL: Point = Point(plotLegend.legendTopLeft.x + plotLegend.legendTextSize, plotLegend.legendTopLeft.y - (2.0*Float(i) + 1.0)*plotLegend.legendTextSize)
            let bR: Point = Point(tL.x + plotLegend.legendTextSize, tL.y - plotLegend.legendTextSize)
            let tR: Point = Point(bR.x, tL.y)
            let bL: Point = Point(tL.x, bR.y)
            renderer.drawSolidRect(topLeftPoint: tL,
                                   topRightPoint: tR,
                                   bottomRightPoint: bR,
                                   bottomLeftPoint: bL,
                                   fillColor: legendSeries[i].color,
                                   hatchPattern: .none,
                                   isOriginShifted: false)
            let p: Point = Point(bR.x + plotLegend.legendTextSize, bR.y)
            renderer.drawText(text: legendSeries[i].label,
                              location: p,
                              textSize: plotLegend.legendTextSize,
                              strokeWidth: 1.2,
                              angle: 0,
                              isOriginShifted: false)
        }

    }

    func saveImage(fileName name: String, renderer: Renderer) {
        renderer.drawOutput(fileName: name)
    }

}