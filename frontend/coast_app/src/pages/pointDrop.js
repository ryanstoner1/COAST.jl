// 
const releaseBounds = (e,chartRef) => {

    const chartLocal = chartRef.current.chart;
    let pointInd = e.target.index;

    // get rid of bounds set during dragging
    if (e.target.series.index === 0) {
        if (chartLocal.series[0].xData.length>(pointInd+1)) {
            chartLocal.series[0].options.dragDrop.dragMaxX = chartLocal.axes[0].max;
        };
        if (pointInd>0) {
            chartLocal.series[0].options.dragDrop.dragMinX = chartLocal.axes[0].min;
        };
    }
    console.log(chartLocal.series[0].options.dragDrop.dragMinX)
    console.log(chartLocal.series[0].options.dragDrop.dragMaxX)
    return null
}

export default releaseBounds
