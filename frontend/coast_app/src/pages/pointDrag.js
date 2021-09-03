const pointDrag = (e, chartRef, setXData, setYData) => {
    
    const chartLocal = chartRef.current.chart;
    let pointInd = e.target.index;
    const newX = e.newPoint.x;
    const newY = e.newPoint.y;
    // need to pull bound axes along with it
    if (e.target.series.index === 0) {
        
        if (chartLocal.series[0].xData.length>(pointInd+1)) {
            chartLocal.series[0].options.dragDrop.dragMaxX = chartLocal.series[0].xData[(pointInd+1)]-0.1;
        };
        if (pointInd>0) {
            chartLocal.series[0].options.dragDrop.dragMinX = chartLocal.series[0].xData[(pointInd-1)]+0.1;
        };


        const oldDataX = {...chartLocal.series[(2*pointInd+1)]};
        const oldDataY = {...chartLocal.series[(2*pointInd+2)]};
        const diffXPlus = oldDataX.xData[1] - oldDataX.xData[2];
        const diffXMinus = oldDataX.xData[1] - oldDataX.xData[0];
        const diffYPlus = oldDataY.yData[1] - oldDataY.yData[2];
        const diffYMinus = oldDataY.yData[1] - oldDataY.yData[0];
        const newDataXBound = [{x:(newX-diffXMinus),y:newY},{x:newX,y:newY},{x:(newX-diffXPlus),y:newY}];
        const newDataYBound = [{x:newX,y:(newY-diffYMinus)},{x:newX,y:newY},{x:newX,y:(newY-diffYPlus)}];


        chartLocal.series[2*pointInd+1].setData(newDataXBound);
        chartLocal.series[2*pointInd+2].setData(newDataYBound); 

        setXData( value =>
            value.map(item => {
                if (item.ind === pointInd) {
                    return {ind: pointInd, val : JSON.parse(JSON.stringify(newDataXBound)), check: item.check, disabled: item.disabled} 
                } else {
                    return item 
                }}
        )); 
        setYData( value =>
            value.map(item => {
                if (item.ind === pointInd) {
                    return {ind: pointInd, val : JSON.parse(JSON.stringify(newDataYBound)), check: false, disabled: item.disabled} 
                } else {
                    return item 
                }}
        ));          
    } else if (e.target.series.index > 0) {
        // whether x or y direction being dragged

        if (e.target.series.index % 2 === 1) {
            const pointInd = (e.target.series.index - 1)/2
            const oldDataX = {...chartLocal.series[e.target.series.index]};
            // have to repeat due to scoping issues
            if (e.target.index===2) {                    
                const newDataXBound = [{x:oldDataX.xData[0],y:oldDataX.yData[0]},{x:oldDataX.xData[1],y:oldDataX.yData[1]},{x:e.target.x,y:e.target.y}];
                setXData( value =>
                    value.map(item => {
                        if (item.ind === pointInd) {
                            return {ind: pointInd, val : JSON.parse(JSON.stringify(newDataXBound)), check: item.check, disabled: item.disabled} 
                        } else {
                            return item 
                        }}
                )); 
                
            } else {
                const newDataXBound = [{x:e.target.x,y:e.target.y},{x:oldDataX.xData[1],y:oldDataX.yData[1]},{x:oldDataX.xData[2],y:oldDataX.xData[2]}];
                setXData( value =>
                    value.map(item => {
                        if (item.ind === pointInd) {
                            return {ind: pointInd, val : JSON.parse(JSON.stringify(newDataXBound)), check: item.check, disabled: item.disabled} 
                        } else {
                            return item 
                        }}
                )); 

            }

            const highIndex = ((e.target.series.index-1)/2)+1
            const lowIndex = ((e.target.series.index-1)/2)-1
            if (chartLocal.series[0].xData.length>=(highIndex)) {
                chartLocal.series[e.target.series.index].options.dragDrop.dragMaxX = chartLocal.series[0].xData[highIndex]-0.1;
            }
            if (lowIndex >= 0) {
                chartLocal.series[e.target.series.index].options.dragDrop.dragMinX = chartLocal.series[0].xData[lowIndex]+0.1;
            }
            
        } else {
            const oldDataY = {...chartLocal.series[e.target.series.index]};
            const diffYPlus = oldDataY.yData[1] - oldDataY.yData[2];
            const diffYMinus = oldDataY.yData[1] - oldDataY.yData[0];
            const newDataYBound = [{x:newX,y:(newY-diffYMinus)},{x:newX,y:newY},{x:newX,y:(newY-diffYPlus)}];
            setYData( value =>
                value.map(item => {
                    if (item.ind === pointInd) {
                        return {ind: pointInd, val : JSON.parse(JSON.stringify(newDataYBound)), check: false, disabled: item.disabled} 
                    } else {
                        return item 
                    }}
            ));
        }
                     
    }
};
export default pointDrag