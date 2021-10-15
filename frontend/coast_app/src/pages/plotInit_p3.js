
const plotInit = (initChartClick, initPointClick, pointDrag, releaseBounds, initP1, 
    initXBoundP1, initYBoundP1, chartRef, handleContextMenu, 
    hideContextMenu, setXData, setYData, errorVisibleX=false, errorVisibleY=false, maxTime=140, maxTemp=200) => {
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
                title: { 
                    text: "time (Ma)",            
                    style: {
                        fontSize: '20px'
                    }
                },
                min: 0,
                max: maxTime,
                reversed: true,
                labels: {
                    style: {
                        fontSize: '18px'
                    }
                }
            },
            yAxis: {
                gridLineWidth: 0,
                min: 0,
                max: maxTemp,
                title: { 
                    text: "temperature (ºC)",            
                    style: {
                        fontSize: '20px'
                    }
                },
                reversed: true,
                labels: {
                    style: {
                        fontSize: '18px'
                    }
                }
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
                    visible: errorVisibleX,
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
                    visible: errorVisibleY,
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
                    },
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
                            drop: (e) => {
                                releaseBounds(e, chartRef);
                            },
                        }
                    }
                }
            }
        };
        return plotObj
};


export default plotInit