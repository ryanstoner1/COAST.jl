
const plotInitXYZ = (dataObj, xlabelXY) => {


    const plotObj = {
            tooltip: { 
                animation:false,
                enabled: false },
            title: {
                text: 'Output X-Y-(Z) plot',
                align: 'center'
            },
            animation: false,
            xAxis: {
                title: { text: xlabelXY,          
                    style: {
                        fontSize: '20px'
                    }
            },
            labels: {
                style: {
                    fontSize: '18px'
                }
            }
            },
            yAxis: {
                gridLineWidth: 0,
                title: { text: "Date (Ma)",          
                style: {
                    fontSize: '20px'
                }},
                labels: {
                    style: {
                        fontSize: '18px'
                    }
                },
            },
            series: 
                dataObj.rawdata.map((value,ind)=>{
                    return {
                        type: 'line',
                        linkedto: 'series-1',
                        color: "black",
                        showInLegend: false,
                        dragDrop: {
                            draggableY: false,
                            draggableX: false
                        },
                        data: value,
                        name: dataObj.names[ind],
                        marker: {
                            enabled: false
                        },
                    }
                })
            ,
            chart: {
                plotBorderWidth: 2,
                animation: false,
            },     
        };
        return plotObj
};


export default plotInitXYZ