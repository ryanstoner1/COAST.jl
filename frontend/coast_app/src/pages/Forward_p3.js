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
import initChartClick from './initChartClick.js';
import initPointClick from './initPointClick.js';
import { timeContextMenu, temperatureContextMenu } from './contextMenu.js';
import pointDrag from './pointDrag.js'
import { handleCheckFlowers09, handleCheckX, handleCheckY } from './handleChecking.js';

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

    const initXYx1 = 20
    const initXYy1 = 30
    const dataXY1 = [{x:initXYx1, y:initXYy1+15}, {x:initXYx1+50, y:initXYy1+105}, {x:initXYx1+105, y:initXYy1+205}];
    const dataXY2 = [{x:initXYx1-5, y:initXYy1}, {x:initXYx1, y:initXYy1+10}, {x:initXYx1+15, y:initXYy1+25}];
    const dataValsXY = [dataXY1, dataXY2]
    const [dataXY, setDataXY] = useState(dataValsXY)
    // add points
    // errorbar in x direction does not exist in highcharts therefore using line
    // simpler to add invisible error bar in each case and then only process visible "error bars"

    const initx1 = 10.0;
    const inity1 = 20.0;
    const initP1 = [{ x: initx1, y: inity1 }];
    const initXBoundP1 = [{x:initx1-15, y:inity1},{x:initx1, y:inity1},{x:initx1+15, y:inity1}];
    const initYBoundP1 = [{x:initx1, y:inity1-30},{x:initx1, y:inity1},{x:initx1, y:inity1+30}];
    const [options, setOptions] = useState(plotInit(initChartClick, initPointClick, pointDrag, 
        initP1, initXBoundP1, initYBoundP1, chartRef, handleContextMenu, hideContextMenu, setXData, setYData));
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

        return (
            <div id='testing2' onClick={handleNonchartClick}>
            <div>
            { menu ? <Menu 
            xPos={xPos} yPos={yPos} 
            chartRef={chartRef} indPoint={indPoint} maxChecked={maxChecked} 
            xData={xData} yData={yData} setXData={setXData} setYData={setYData}
            timeContextMenu={timeContextMenu} temperatureContextMenu={temperatureContextMenu}
            /> : null }
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
                    <Diff chartRef={chartRef} xData={xData} yData={yData} checkedList={checkedList} maxChecked={maxChecked} onCheckChange={(e)=>handleCheckFlowers09(e,xData,yData,setXData,setYData,setMaxChecked,checkedList, setCheckedList)} 
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
                            <input type="checkbox" id="vehicle1" name="vehicle1" disabled={point.disabled} value={[index,"x"]} onChange={(e) => handleCheckX(e,point.ind,point.check,xData,yData,setXData,setYData,checkedList,setMaxChecked)} checked={point.check}/>
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
                            <input type="checkbox" id="vehicle1" name="vehicle1" disabled={point.disabled} value={[index,"y"]} onChange={(e) => handleCheckY(e,point.ind,point.check,xData,yData,setXData,setYData,checkedList,setMaxChecked)} checked={point.check}/>
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