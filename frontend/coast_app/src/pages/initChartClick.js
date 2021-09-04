
const initChartClick = (e, chartRef, lowX=15, lowY=30, highX=15, highY=30, visibleY=false, draggableY=false) => {
        const chartLocal = chartRef.current.chart;

        chartLocal.series[0].addPoint({ x: e.xAxis[0].value, y: e.yAxis[0].value});

         const checkIndex = (point) => {
            return (Math.abs(point.x-e.xAxis[0].value)<1e-15) & (Math.abs(point.y-e.yAxis[0].value)<1e-15)
         };
        // end adding point to base plot

        // error bar section
        // need to retrieve point to pass to our "error bar" approach
        const indexAddedPoint = chartLocal.series[0].data.findIndex(checkIndex);
        const xPointNew = e.xAxis[0].value;
        const yPointNew = e.yAxis[0].value;

        //let newOptions = { ...options };
        // causes flickering otherwise
        //newOptions.plotOptions.series.marker = {states: {hover: {enabled: false}}};
        const dataNewX = [{x:xPointNew-lowX, y:yPointNew},{x:xPointNew, y:yPointNew},{x:xPointNew+highX, y:yPointNew}];
        const dataNewY = [{x:xPointNew-0.001, y:yPointNew-lowY},{x:xPointNew, y:yPointNew},{x:xPointNew+0.001, y:yPointNew+highY}];
        const lastSeriesIndex = chartLocal.series.length - 1;
        
        const idX = (2*indexAddedPoint+1);
        const idY = (2*indexAddedPoint+2);

        // need to shift index of previously added points else indices will conflict 
        if (xPointNew<chartLocal.series[lastSeriesIndex].xData[1]) {
            const seriesSlice = [...chartRef.current.chart.series.slice(2*indexAddedPoint+1)];

            seriesSlice.forEach((element,i) => {
                element.options.index = (2*indexAddedPoint+i+3);
            }); 
        };

        // options
        const newSeriesX = {
            type: 'line',
            findNearestPointBy: 'xy',
            stickyTracking: false,
            visible: false,
            index: idX,
            linkedto: 'series-1',
            showInLegend: false,
            dragDrop: {
                draggableY: false,
                draggableX: false
            },
            color: "black",
            data: [...dataNewX],
            marker: {
                enabled: false
            }
        };
        const newSeriesY = {
            type: 'line',
            findNearestPointBy: 'xy',
            visible: visibleY,
            index: idY,
            stickyTracking: false,
            linkedto: 'series-1',
            showInLegend: false,
            dragDrop: {
                draggableY: draggableY,
                draggableX: false
            },
            color: "black",
            data: [...dataNewY],
            marker: {
                enabled: false
            }
        };

        // add error bar; x and y direction
        chartRef.current.chart.addSeries(newSeriesX);
        chartRef.current.chart.addSeries(newSeriesY);

    };

export default initChartClick