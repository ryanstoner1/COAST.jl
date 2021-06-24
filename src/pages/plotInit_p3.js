
const plotInit = (initChartClick, initPointClick, pointDrag) => {
    const initx1 = 10.0
    const inity1 = 20.0
    const initP1 = [{ x: initx1, y: inity1 }];
    const initXBoundP1 = [{x:initx1-15, y:inity1},{x:initx1, y:inity1},{x:initx1+15, y:inity1}];
    const initYBoundP1 = [{x:initx1, y:inity1-30},{x:initx1, y:inity1},{x:initx1, y:inity1+30}];
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
                        initChartClick(e);
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
                    stickyTracking: false,
                    allowPointSelect: true,
                    connectNulls: false,
                    point: {
                        events: {
                            click: (e) => {
                                initPointClick(e)
                            },
                            drag: (e) => {
                                pointDrag(e)
                            },
                        }
                    }
                }
            }
        };
        return plotObj
};


export default plotInit