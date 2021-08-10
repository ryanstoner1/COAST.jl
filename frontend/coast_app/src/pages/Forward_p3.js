import React, { useEffect, useState, useRef, useCallback} from 'react';
import Highcharts from 'highcharts/highcharts';
import HighchartsReact from 'highcharts-react-official';
import addExporting from "highcharts/modules/exporting";
import moreExporting from "highcharts/modules/export-data";
import {ButtonGroup, ToggleButton, InputGroup, FormControl, Dropdown, DropdownButton} from 'react-bootstrap';
import plotInit from './plotInit_p3.js'
import plotInitXY from './plotInitXY_p3.js'
import Menu from './Menu_p3.js'
import Diff from './diffusion_models_p3.js'
import "./styles.css";
addExporting(Highcharts);
moreExporting(Highcharts);
require('highcharts/highcharts-more')(Highcharts);
require("highcharts/modules/draggable-points")(Highcharts);



/**
 * Main app:
 * used 
 */
export default function CoastApp() {
    const [diffusionParams, setDiffusionParams] = useState({model: false});
    const [checkedList, setCheckedList] = useState([])
    const [maxChecked, setMaxChecked] = useState(false)
    const [indPoint, setIndPoint] = useState(null);
    const [xPos, setXPos] = useState("0px");
    const [yPos, setYPos] = useState("0px");
    const [radioValue, setRadioValue] = useState('1');

    // only visible data
    const [xData,setXData] = useState([]);
    const [yData,setYData] = useState([]);
    const [menu, showMenu] = useState(false);
    const chartRef = useRef(null);   
    const [isChartXY, setIsChartXY] = useState(false); 

    const radios = [
        { name: ' X-Y plot', value: '1' },
        { name: ' Global sensitivity', value: '2' },
    ];
    const hideContextMenu = useCallback(() => {
        showMenu(false);
    }, [showMenu]);

    const handleContextMenu = useCallback(
        event => {
          event.preventDefault();
            setIndPoint(event.point.index);
            setXPos(`${event.point.plotX}px`);
            setYPos(`${event.point.plotY}px`);
            showMenu(true);            
        },
        [showMenu, setXPos, setYPos, setIndPoint]
    );

    const timeContextMenu = (e) => {
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


    const temperatureContextMenu = (e) => {

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
    const initx1 = 20
    const inity1 = 30
    const dataXY1 = [{x:initx1, y:inity1+15}, {x:initx1+50, y:inity1+105}, {x:initx1+105, y:inity1+205}];
    const dataXY2 = [{x:initx1-5, y:inity1}, {x:initx1, y:inity1+10}, {x:initx1+15, y:inity1+25}];
    const dataValsXY = [dataXY1, dataXY2]
    const [dataXY, setDataXY] = useState(dataValsXY)
    // add points
    // errorbar in x direction does not exist in highcharts therefore using line
    // simpler to add invisible error bar in each case and then only process visible "error bars"
    const initChartClick = (e) => {
        const chartLocal = chartRef.current.chart;

        chartLocal.series[0].addPoint({ x: e.xAxis[0].value, y: e.yAxis[0].value});

         const checkIndex = (point) => {
            return (Math.abs(point.x-e.xAxis[0].value)<1e-15) & (Math.abs(point.y-e.yAxis[0].value)<1e-15)
         };
        // end adding point to base plot

        // error bar section
        // need to retrieve point to pass to our "error bar" approach
        const indexAddedPoint = chartLocal.series[0].data.findIndex(checkIndex);
        const xPointNew = e.xAxis[0].value;
        const yPointNew = e.yAxis[0].value;

        let newOptions = { ...options };
        // causes flickering otherwise
        newOptions.plotOptions.series.marker = {states: {hover: {enabled: false}}};
        const dataNewX = [{x:xPointNew-15, y:yPointNew},{x:xPointNew, y:yPointNew},{x:xPointNew+15, y:yPointNew}];
        const dataNewY = [{x:xPointNew-0.001, y:yPointNew-30},{x:xPointNew, y:yPointNew},{x:xPointNew+0.001, y:yPointNew+30}];
        const lastSeriesIndex = chartLocal.series.length - 1;
        
        const idX = (2*indexAddedPoint+1);
        const idY = (2*indexAddedPoint+2);

        // need to shift index of previously added points else indices will conflict 
        if (xPointNew<chartLocal.series[lastSeriesIndex].xData[1]) {
            const seriesSlice = [...chartRef.current.chart.series.slice(2*indexAddedPoint+1)];

            seriesSlice.forEach((element,i) => {
                element.options.index = (2*indexAddedPoint+i+3);
            }); 
        };

        // options
        const newSeriesX = {
            type: 'line',
            findNearestPointBy: 'xy',
            stickyTracking: false,
            visible: false,
            index: idX,
            linkedto: 'series-1',
            showInLegend: false,
            dragDrop: {
                draggableY: false,
                draggableX: false
            },
            color: "black",
            data: [...dataNewX],
            marker: {
                enabled: false
            }
        };
        const newSeriesY = {
            type: 'line',
            findNearestPointBy: 'xy',
            visible: false,
            index: idY,
            stickyTracking: false,
            linkedto: 'series-1',
            showInLegend: false,
            dragDrop: {
                draggableY: false,
                draggableX: false
            },
            color: "black",
            data: [...dataNewY],
            marker: {
                enabled: false
            }
        };

        // add error bar; x and y direction
        chartRef.current.chart.addSeries(newSeriesX);
        chartRef.current.chart.addSeries(newSeriesY);

        };

    // remove point
    const initPointClick = (e) => {        
        if (e.altKey) {
            handleContextMenu(e);
        } else {
            hideContextMenu();
            const chartLocal = chartRef.current.chart;
            let indCur = e.point.index;

            chartLocal.series[0].removePoint(e.point.index);
            const indSeriesX = (2*indCur+1);
            const indSeriesY = (2*indCur+1);

            // need to downshift indices since point removed
            if (chartRef.current.chart.series.length>(indSeriesX+2)) {
                const seriesSlice = [...chartRef.current.chart.series.slice(indSeriesX+2)];
                seriesSlice.forEach((element,i) => {
                    element.options.index = (indSeriesX+i);
                }); 
            };
            chartRef.current.chart.series[indSeriesX].remove();
            chartRef.current.chart.series[indSeriesY].remove();

        };
    };

    const pointDrag = (e) => {
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

    const [options, setOptions] = useState(plotInit(initChartClick, initPointClick, pointDrag));
    const optionsXY = plotInitXY(dataXY);
    
    const handleXMin = (e,index,chartRef) => {        
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

    const handleXMax = (e,index,chartRef) => {        
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

    const handleYMin = (e,index,chartRef) => {        
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

    const handleYMax = (e,index,chartRef) => {        
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
    // Delete points with x key
    useEffect((event) => {
        // delete last point in series with backspace
        const handleKeyDown = (event) => {            
            const deleteKey = 88
            const chartLocal = chartRef.current.chart;
            if (event.keyCode === deleteKey) {
                chartLocal.series[0].setData(options.series[0].data.filter((element, index) => {
                    
                    return (index !== (options.series[0].data.length - 1))
                }));
            }        
        };
    window.addEventListener('keydown', handleKeyDown);
    // cleanup this component
    return () => {
        window.removeEventListener('keydown', handleKeyDown);
    };
    }, [options.series]);
    
    const handleNonchartClick = (e) => {
        if (!e.altKey) {
            hideContextMenu();
        }
    };

    const handleDiffModel = (e,diffModelType) => {
        setDiffusionParams({model: diffModelType})
    };

    const handleCheckX = (e,pointInd,pointCheck) => {

        setXData(value => value.map(item=> {
            if (item.ind === pointInd & item.check === true) {
                return {ind: pointInd, val : [...item.val], check: false, disabled: item.disabled} 
            } else if (item.ind === pointInd & item.check === false) {
                return {ind: pointInd, val : [...item.val], check: true, disabled: item.disabled} 
            } else {
                return item
            }}))
        isDisabled(xData,yData,checkedList,pointCheck)
    };

    const handleCheckY = (e,pointInd,pointCheck) => {
        
        
        setYData(value => value.map(item=> {
            
            if (item.ind === pointInd & item.check === true) {

                return {ind: pointInd, val : [...item.val], check: false, disabled: item.disabled} 
            } else if (item.ind === pointInd & item.check === false) {

                return {ind: pointInd, val : [...item.val], check: true, disabled: item.disabled} 
            } else {
                return item
            }}))
        isDisabled(xData,yData,checkedList,pointCheck)
    };

    const isDisabled = (xData,yData,checkedList,pointCheck) => {
        
        const countCopyY = [...yData];
        const countCheckY = countCopyY.filter((countCopyY) => countCopyY.check === true).length;
        const countCopyX = [...xData];
        const countCheckX = countCopyX.filter((countCopyX) => countCopyX.check === true).length;
        const checkedListCopy = [...checkedList];
        let totalCount = countCheckX + countCheckY + checkedListCopy.length;
        if (pointCheck === false) {
            totalCount = totalCount + 1;
        } else {
            totalCount = totalCount - 1;
        };
        
        
        if (totalCount > 1) {
            setMaxChecked(true)
            setXData(value => value.map((item, index)=> {
                const newItem = {...item}

                
                if (item.check === true) {
                    newItem.disabled = false
                    return newItem
                } else if (item.check === false) {
                    newItem.disabled = true
                    return newItem
                } else {
                    return item
            }}))

            setYData(value => value.map((item, index)=> {
                const newItem = {...item}

                if (item.check === true) {                    
                    newItem.disabled = false
                    return newItem
                } else if (item.check === false) {
                    newItem.disabled = true                   
                    return newItem
                } else {
                    return item
            }}))
        } else {
            setMaxChecked(false)
            setXData(value => value.map((item, index)=> {
                
                if (item.disabled === true) {
                    return {ind: item.ind, val : item.val, check: item.check, disabled: false} 
                } else {
                    
                    return item
            }}))

            setYData(value => value.map((item, index)=> {


                if (item.disabled === true) {
                    return {ind: item.ind, val : item.val, check: item.check, disabled: false} 
                } else {
                    
                    return item
            }}))    
            
        }
    }

    const handleCheckFlowers09 = (e,xData,yData,checkedList) => {
        let pointCheck = e.target.checked ? false : true
        if (e.target.checked ===true) {
            setCheckedList(checkedList => [...checkedList,e.target.value]);
        } else {
            setCheckedList(checkedList.filter(value => value!==e.target.value));
        } 

        isDisabled(xData,yData,checkedList, pointCheck)
      
    };



        return (
            <div id='testing2' onClick={handleNonchartClick}>
            <div>
            { menu ? <Menu xPos={xPos} yPos={yPos} timeContextMenu={timeContextMenu} temperatureContextMenu={temperatureContextMenu}/> : null }
            </div>
                <div>
                    <HighchartsReact
                        highcharts={Highcharts}
                        options={options}
                        ref={chartRef}
                    />
                </div>
                <p>Date (Ma): N.A.</p>
                <br></br>
                <ButtonGroup toggle>
                    {radios.map((radio, idx) => (
                    <ToggleButton
                        key={idx}
                        type="checkbox"
                        variant="secondary"
                        name="radio"
                        value={radio.value}
                        checked={radioValue === radio.value}
                        onChange={(e) => setRadioValue(e.currentTarget.value)}
                    >
                        {radio.name}
                    </ToggleButton>
                    ))}
                </ButtonGroup>
                <div>
                    <DropdownButton id="dropdown-p3" title="Add diffusion parameters">
                    <Dropdown.Item href="#/action-1">U-Pb Ap. (Cherniak, 2000)</Dropdown.Item>
                    <Dropdown.Item href="#/action-2" onClick={(e) => {handleDiffModel(e,"flowers09")}}>(U-Th)/He Ap. (Flowers et, 2009)</Dropdown.Item>
                    </DropdownButton>
                <br></br>
                { (diffusionParams.model==="flowers09") ?
                    <Diff chartRef={chartRef} xData={xData} yData={yData} checkedList={checkedList} maxChecked={maxChecked} onCheckChange={handleCheckFlowers09} 
                        setIsChartXY={setIsChartXY} setDataXY={setDataXY} radioValue={radioValue}
                    />
                : null}
                { (diffusionParams.model==="cherniak00") ?
                    <div>TODO: cherniak, 2000 U-Pb</div>
                : null}
                <br></br>
                </div>
                
                <br></br>
                { (xData.length) ? 
                <div>
                    <br></br>
                    {xData.map((point, index) => (
                        <div key={index}>
                            <InputGroup className="mb-3">
                            <InputGroup.Prepend>
                            <InputGroup.Text type="checkbox" >
                            <div>
                                varying <i>time</i> at point {index+1} at time {Math.round((point.val[1].x + Number.EPSILON) * 10) / 10} Ma (min/max)
                            </div>
                            <div>
                                &nbsp;
                            </div>
                            <input type="checkbox" id="vehicle1" name="vehicle1" disabled={point.disabled} value={[index,"x"]} onChange={(e) => handleCheckX(e,point.ind,point.check)} checked={point.check}/>
                            </InputGroup.Text>
                            </InputGroup.Prepend>
                            <FormControl type="number" placeholder={`min: ${Math.round((point.val[0].x + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleXMin(e,point.ind,chartRef)}/>
                            <FormControl type="number" placeholder={`max: ${Math.round((point.val[2].x + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleXMax(e,point.ind,chartRef)}/>
                            </InputGroup>                            
                        </div>
                    )
                    )}
                </div> : null}
                { (yData.length) ? 
                <div>
                    {yData.map((point, index) => (
                        <div key={index}>
                            <InputGroup className="mb-3">
                            <InputGroup.Prepend>
                            <InputGroup.Text type="checkbox" >
                            <div>
                                varying <i>temperature </i> at point {index+1} at temperature {Math.round((point.val[1].y + Number.EPSILON) * 10) / 10} ºC (min/max)
                            </div>
                            <div>
                                &nbsp;
                            </div>
                            <input type="checkbox" id="vehicle1" name="vehicle1" disabled={point.disabled} value={[index,"y"]} onChange={(e) => handleCheckY(e,point.ind,point.check)} checked={point.check}/>
                            </InputGroup.Text>
                            </InputGroup.Prepend>
                            <FormControl type="number" placeholder={`min: ${Math.round((point.val[0].y + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleYMin(e,point.ind,chartRef)}/>
                            <FormControl type="number" placeholder={`max: ${Math.round((point.val[2].y + Number.EPSILON) * 10) / 10}`} onKeyPress={(e) => handleYMax(e,point.ind,chartRef)}/>
                            </InputGroup>                            
                        </div>
                    )
                    )}
                </div> : null}
                { (isChartXY===true) ? <div>
                    <HighchartsReact
                        highcharts={Highcharts}
                        options={optionsXY}
                    />
                </div> : null}
            </div>
        );  
}

