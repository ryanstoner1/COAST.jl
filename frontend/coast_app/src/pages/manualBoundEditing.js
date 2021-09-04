const handleXMin = (e,index,chartRef,setXData) => {        
    if (e.key === "Enter") {
        setXData(value => value.map((point,ind) => {
            if (point.ind===index) {
                const newPoint = {...point};
                newPoint.val[0].x = e.target.valueAsNumber;
                const newXData = JSON.parse(JSON.stringify(chartRef.current.chart.series[2*index+1].options.data))
                newXData[0].x = e.target.valueAsNumber;
                chartRef.current.chart.series[2*index+1].setData(newXData);  
 
                return newPoint
            } else {
                return point
            }    
        }));
    }
};

const handleXMax = (e,index,chartRef,setXData) => {        
    if (e.key === "Enter") {
        setXData(value => value.map((point,ind) => {
            if (point.ind===index) {
                const newPoint = {...point};
                newPoint.val[2].x = e.target.valueAsNumber;
                const newXData = JSON.parse(JSON.stringify(chartRef.current.chart.series[2*index+1].options.data))
                newXData[2].x = e.target.valueAsNumber;
                chartRef.current.chart.series[2*index+1].setData(newXData);  
 
                return newPoint
            } else {
                return point
            }    
        }));
    }
};

const handleYMin = (e,index,chartRef,setYData) => {        
    if (e.key === "Enter") {
        setYData(value => value.map((point,ind) => {
            if (point.ind===index) {
                const newPoint = {...point};
                newPoint.val[0].y = e.target.valueAsNumber;
                const newYData = JSON.parse(JSON.stringify(chartRef.current.chart.series[2*index+2].options.data))
                newYData[0].y = e.target.valueAsNumber;
                chartRef.current.chart.series[2*index+2].setData(newYData);  
 
                return newPoint
            } else {
                return point
            }    
        }));
    }
};

const handleYMax = (e,index,chartRef,setYData) => {        
    if (e.key === "Enter") {
        setYData(value => value.map((point,ind) => {
            if (point.ind===index) {
                const newPoint = {...point};
                newPoint.val[2].y = e.target.valueAsNumber;
                const newYData = JSON.parse(JSON.stringify(chartRef.current.chart.series[2*index+2].options.data))
                newYData[2].y = e.target.valueAsNumber;
                chartRef.current.chart.series[2*index+2].setData(newYData);  
 
                return newPoint
            } else {
                return point
            }    
        }));
    }
};

export {handleXMin, handleXMax, handleYMin, handleYMax}