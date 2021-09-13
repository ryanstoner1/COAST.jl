// dropdown functionality when alt-clicking point on chart
// either adds or gets rid of errorbars 
const handleTimeSelectMenu = (chartRef, indPoint, maxChecked, tData, settData) => {
    if (chartRef.current.chart.series[(2*indPoint+1)].visible===false) {
        chartRef.current.chart.series[(2*indPoint+1)].show();
        chartRef.current.chart.series[(2*indPoint+1)].options.dragDrop = {
            draggableX: true, draggableY: false
        };
        
        const tNew = [...chartRef.current.chart.series[(2*indPoint+1)].xData];
        const TNew = [...chartRef.current.chart.series[(2*indPoint+1)].yData];
        const tNewAdd = [{x: tNew[0], y: TNew[0]},{x: tNew[1], y: TNew[1]},{x: tNew[2], y: TNew[2]}];
        const maxCheckedCopy = maxChecked;

        // errors if empty 
        if (maxCheckedCopy=== true) {
            settData([...tData,{ind: indPoint, val: [...tNewAdd], check: false, disabled: true}]);
        } else {
            settData([...tData,{ind: indPoint, val: [...tNewAdd], check: false, disabled: false}]);
        }
                
    } else {
        chartRef.current.chart.series[(2*indPoint+1)].hide();
        settData(tData => tData.filter(value => value.ind!==(indPoint)));

        chartRef.current.chart.series[(2*indPoint+1)].options.dragDrop = {
            draggableX: false, draggableY: false
        };
    };
};


const handleTemperatureSelectMenu = (chartRef, indPoint, maxChecked, TData, setTData) => {

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
            setTData([...TData,{ind: indPoint, val: [...yNewAdd], check: false, disabled: true}]);
        } else {
            setTData([...TData,{ind: indPoint, val: [...yNewAdd], check: false, disabled: false}]);
        }
    } else {
        chartRef.current.chart.series[(2*indPoint+2)].hide();
        chartRef.current.chart.series[(2*indPoint+2)].options.dragDrop = {
            draggableX: false, draggableY: false
        };
        setTData(TData => TData.filter(value => value.ind!==(indPoint)));
    };
};

export { handleTimeSelectMenu, handleTemperatureSelectMenu}