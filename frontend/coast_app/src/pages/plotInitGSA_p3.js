
const plotInitGSA = (dataObj) => {
    
     const plotObj = {
        chart: {
            type: 'column'
        },
        title: {
            text: 'Sensitivity Indices'
        },
        subtitle: {
            text: ''
        },
        legend: {
            itemStyle: {
                fontSize: "20px"
            }
        },
        xAxis: {
            categories: dataObj.categories,
            crosshair: true,
            labels: {
                style: {
                    fontSize: '20px'
                }
            }
        },
        yAxis: {
            min: 0,
            max: 100,
            title: {
                text: 'sensitivity index (% variance)',            
                style: {
                    fontSize: '20px'
                }
            },
            labels: {
                style: {
                    fontSize: '20px'
                }
            }
        },
        plotOptions: {
            column: {
                pointPadding: 0.2,
                borderWidth: 0
            }
        },
        series: [{
            //type: 'column',
            name: '1st order',
            data: dataObj.order1
        },
        {
            //type: 'column',
            name: 'total sensitivity',
            data: dataObj.order_total
        },]
    };
         return plotObj
 };


export default plotInitGSA