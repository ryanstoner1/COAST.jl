// dropdown functionality when alt-clicking point on chart
// either adds or gets rid of errorbars 
const timeContextMenu = (e, chartRef, indPoint, maxChecked, xData, setXData) => {
    if (chartRef.current.chart.series[(2*indPoint+1)].visible===false) {
        chartRef.current.chart.series[(2*indPoint+1)].show();
        chartRef.current.chart.series[(2*indPoint+1)].options.dragDrop = {
            draggableX: true, draggableY: false
        };
        
        const xNew = [...chartRef.current.chart.series[(2*indPoint+1)].xData];
        const yNew = [...chartRef.current.chart.series[(2*indPoint+1)].yData];
        const xNewAdd = [{x: xNew[0], y: yNew[0]},{x: xNew[1], y: yNew[1]},{x: xNew[2], y: yNew[2]}];
        const maxCheckedCopy = maxChecked;

        // errors if empty 
        if (maxCheckedCopy=== true) {
            setXData([...xData,{ind: indPoint, val: [...xNewAdd], check: false, disabled: true}]);
        } else {
            setXData([...xData,{ind: indPoint, val: [...xNewAdd], check: false, disabled: false}]);
        }
                
    } else {
        chartRef.current.chart.series[(2*indPoint+1)].hide();
        setXData(xData => xData.filter(value => value.ind!==(indPoint)));

        chartRef.current.chart.series[(2*indPoint+1)].options.dragDrop = {
            draggableX: false, draggableY: false
        };
    };
};


const temperatureContextMenu = (e, chartRef, indPoint, maxChecked, yData, setYData) => {

    if (chartRef.current.chart.series[(2*indPoint+2)].visible===false) {
        chartRef.current.chart.series[(2*indPoint+2)].show();
        chartRef.current.chart.series[(2*indPoint+2)].options.dragDrop = {
            draggableX: false, draggableY: true
        };
        const xNew = [...chartRef.current.chart.series[(2*indPoint+2)].xData];
        const yNew = [...chartRef.current.chart.series[(2*indPoint+2)].yData];
        const yNewAdd = [{x: xNew[0], y: yNew[0]},{x: xNew[1], y: yNew[1]},{x: xNew[2], y: yNew[2]}];

        const maxCheckedCopy = maxChecked;

        // errors if empty 
        if (maxCheckedCopy=== true) {
            setYData([...yData,{ind: indPoint, val: [...yNewAdd], check: false, disabled: true}]);
        } else {
            setYData([...yData,{ind: indPoint, val: [...yNewAdd], check: false, disabled: false}]);
        }
    } else {
        chartRef.current.chart.series[(2*indPoint+2)].hide();
        chartRef.current.chart.series[(2*indPoint+2)].options.dragDrop = {
            draggableX: false, draggableY: false
        };
        setYData(yData => yData.filter(value => value.ind!==(indPoint)));
    };
};

export {timeContextMenu, temperatureContextMenu}