
const plotInit = (initChartClick, initPointClick, pointDrag, initP1, 
    initXBoundP1, initYBoundP1, chartRef, handleContextMenu, 
    hideContextMenu, setXData, setYData) => {
    const plotObj = {
            tooltip: { 
                animation:false,
                enabled: false },
            title: {
                text: 'Temperature-Time Path',
                align: 'center'
            },
            animation: false,
            xAxis: {
                title: { text: "time (Ma)" },
                min: 0,
                max: 400,
                reversed: true
            },
            yAxis: {
                gridLineWidth: 0,
                min: 0,
                max: 400,
                title: { text: "temperature (ºC)" },
                reversed: true
            },
            series: [
                {
                    type: 'line',
                    id: 'series-1',
                    showInLegend: false,
                    dragDrop: {
                        draggableY: true,
                        draggableX: true
                    },
                    zIndex: 1,
                    data: initP1,
                },{
                    type: 'line',
                    linkedto: 'series-1',
                    visible: false,
                    indpoint: 0,
                    color: "black",
                    showInLegend: false,
                    dragDrop: {
                        draggableY: true,
                        draggableX: true
                    },
                    data: initXBoundP1,
                    marker: {
                        enabled: false
                    }
                },{
                    type: 'line',
                    linkedto: 'series-1',
                    visible: false,
                    indpoint: 0,
                    color: "black",
                    showInLegend: false,
                    dragDrop: {
                        draggableY: false,
                        draggableX: false
                    },
                    data: initYBoundP1,
                    marker: {
                        enabled: false
                    }
                }
            ],
            chart: {
                plotBorderWidth: 2,
                animation: false,
                events: {
                    click: (e) => {
                        initChartClick(e, chartRef);
                    }
                }
            },
            exporting: {
                chartOptions: {
                    plotOptions: {
                        series: {
                            dataLabels: {
                                enabled: true
                            }
                        }
                    }
                }
            },
            plotOptions: {
                series: {
                    marker: {
                        states: {
                            hover: {
                                enabled: false
                            }
                        }
                    },
                    stickyTracking: false,
                    allowPointSelect: true,
                    connectNulls: false,
                    point: {
                        events: {
                            click: (e) => {
                                initPointClick(e, chartRef, handleContextMenu, hideContextMenu, setXData, setYData)
                            },
                            drag: (e) => {
                                pointDrag(e, chartRef, setXData, setYData)
                            },
                        }
                    }
                }
            }
        };
        return plotObj
};


export default plotInit