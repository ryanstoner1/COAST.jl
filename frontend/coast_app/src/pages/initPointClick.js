
    
    // remove point
    const initPointClick = (e, chartRef, handleContextMenu, hideContextMenu, setXData, setYData) => {        
        if (e.altKey) {
            handleContextMenu(e);
        } else {
            hideContextMenu();
            const chartLocal = chartRef.current.chart;
            let indCur = e.point.index;

            chartLocal.series[0].removePoint(e.point.index);
            const indSeriesX = (2*indCur+1);
            const indSeriesY = (2*indCur+1);

            // need to downshift indices since point removed
            if (chartRef.current.chart.series.length>(indSeriesX+2)) {
                const seriesSlice = [...chartRef.current.chart.series.slice(indSeriesX+2)];
                seriesSlice.forEach((element,i) => {
                    element.options.index = (indSeriesX+i);
                }); 
            };
            chartRef.current.chart.series[indSeriesX].remove();
            chartRef.current.chart.series[indSeriesY].remove();

            setXData(xData => xData.filter(value => value.ind!==(indCur)));
            setYData(yData => yData.filter(value => value.ind!==(indCur)));
        };
    };

export default initPointClick