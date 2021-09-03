
const plotHeFTy = (maxTime, maxTemp, initP1) => {

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
                max: 1.2*maxTime,
                reversed: true
            },
            yAxis: {
                gridLineWidth: 0,
                min: 0,
                max: 1.2*maxTemp,
                title: { text: "temperature (ºC)" },
                reversed: true
            },
            series: initP1,
            chart: {
                plotBorderWidth: 2,
                animation: false,
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
                    turboThreshold: 0,
                    stickyTracking: false,
                    allowPointSelect: false,
                    marker: {
                            enabled: false
                    }
                }
            }
        };
        return plotObj
};


export default plotHeFTy