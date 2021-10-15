const handletMin = (e,index,chartRef,settData) => {        
    if (e.key === "Enter") {
        settData(value => value.map((point,ind) => {
            if (point.ind===index) {
                const newPoint = {...point};
                newPoint.val[0].x = e.target.valueAsNumber;
                const newtData = JSON.parse(JSON.stringify(chartRef.current.chart.series[2*index+1].options.data))
                newtData[0].x = e.target.valueAsNumber;
                chartRef.current.chart.series[2*index+1].setData(newtData);  
                return newPoint
            } else {
                return point
            }    
        }));
    }
};

const handletMax = (e,index,chartRef,settData) => {        
    if (e.key === "Enter") {
        settData(value => value.map((point,ind) => {
            if (point.ind===index) {
                const newPoint = {...point};
                newPoint.val[2].x = e.target.valueAsNumber;
                const newtData = JSON.parse(JSON.stringify(chartRef.current.chart.series[2*index+1].options.data))
                newtData[2].x = e.target.valueAsNumber;
                chartRef.current.chart.series[2*index+1].setData(newtData);  
                return newPoint
            } else {
                return point
            }    
        }));
    }
};

const handleTMin = (e,index,chartRef,setTData) => {        
    if (e.key === "Enter") {
        setTData(value => value.map((point,ind) => {
            if (point.ind===index) {
                const newPoint = {...point};
                newPoint.val[0].y = e.target.valueAsNumber;
                const newTData = JSON.parse(JSON.stringify(chartRef.current.chart.series[2*index+2].options.data))
                newTData[0].y = e.target.valueAsNumber;
                chartRef.current.chart.series[2*index+2].setData(newTData);   
                return newPoint
            } else {
                return point
            }    
        }));
    }
};

const handleTMax = (e,index,chartRef,setTData) => {        
    if (e.key === "Enter") {
        setTData(value => value.map((point,ind) => {
            if (point.ind===index) {
                const newPoint = {...point};
                newPoint.val[2].y = e.target.valueAsNumber;
                const newTData = JSON.parse(JSON.stringify(chartRef.current.chart.series[2*index+2].options.data))
                newTData[2].y = e.target.valueAsNumber; // temperatures on y axis
                chartRef.current.chart.series[2*index+2].setData(newTData);  
                return newPoint
            } else {
                return point
            }    
        }));
    }
};

export {handletMin, handletMax, handleTMin, handleTMax}