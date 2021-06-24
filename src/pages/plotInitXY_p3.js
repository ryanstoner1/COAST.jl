
const plotInitXY = (data) => {


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
                title: { text: "x" },
            },
            yAxis: {
                gridLineWidth: 0,
                title: { text: "Date (Ma)" },
            },
            series: 
                data.map(value=>{
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
                        marker: {
                            enabled: false
                        }
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


export default plotInitXY