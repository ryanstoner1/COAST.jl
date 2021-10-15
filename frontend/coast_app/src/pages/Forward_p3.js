import React, { useEffect, useState, useRef, useCallback} from 'react';
import Highcharts from 'highcharts/highcharts';
import HighchartsReact from 'highcharts-react-official';
import seriesLabels from "highcharts/modules/series-label";
import addExporting from "highcharts/modules/exporting";
import moreExporting from "highcharts/modules/export-data";
import {ButtonGroup, ToggleButton, Dropdown, DropdownButton} from 'react-bootstrap';
import plotInit from './plotInit_p3.js';
import plotInitXYZ from './plotInitXYZ_p3.js';
import plotInitGSA from './plotInitGSA_p3.js';
import Menu from './Menu_p3.js';
import Diff from './diffusion_models_p3.js';
import initChartClick from './initChartClick.js';
import initPointClick from './initPointClick.js';
import { handleTimeSelectMenu, handleTemperatureSelectMenu} from './contextMenu.js';
import pointDrag from './pointDrag.js';
import releaseBounds from './pointDrop.js';
import { handleCheckFlowers09} from './handleChecking.js';
import {TimeDataCheckList, TempDataCheckList} from './tTChecklistSensitivity.js';

import "./styles.css";
seriesLabels(Highcharts);
addExporting(Highcharts);
moreExporting(Highcharts);
require('highcharts/highcharts-more')(Highcharts);
require("highcharts/modules/draggable-points")(Highcharts);

/**
 * Main app:
 * used 
 */
export default function CoastApp() {
    const [diffusionModel, setDiffusionModel] = useState("");
    const [checkedList, setCheckedList] = useState([])
    const [maxChecked, setMaxChecked] = useState(false)
    const [indPoint, setIndPoint] = useState(null);
    const [xPos, setXPos] = useState("0px");
    const [yPos, setYPos] = useState("0px");
    const [radioValue, setRadioValue] = useState('1');

    // only visible data
    const [tData,settData] = useState([]);
    const [TData,setTData] = useState([]);
    const [menu, showMenu] = useState(false);
    const chartRef = useRef(null);   
    const [isChartXY, setIsChartXY] = useState(false); 
    const [isChartGSA, setIsChartGSA] = useState(false);

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
            setXPos(`${event.clientX}px`);
            setYPos(`${event.clientY}px`);
            showMenu(true);            
        },
        [showMenu, setXPos, setYPos, setIndPoint]
    );

    const initXYx1 = 20
    const initXYy1 = 30
    const dataXY1 = [{x:initXYx1, y:initXYy1+15}, {x:initXYx1+50, y:initXYy1+105}, {x:initXYx1+105, y:initXYy1+205}];
    const dataXY2 = [{x:initXYx1-5, y:initXYy1}, {x:initXYx1, y:initXYy1+10}, {x:initXYx1+15, y:initXYy1+25}];
    const dataValsXY = [dataXY1, dataXY2]
    const [dataXY, setDataXY] = useState({rawdata: dataValsXY, names:[]})
    const [xlabelXY, setXlabelXY] = useState("x")
    const optionsXY = plotInitXYZ(dataXY,xlabelXY);

    const [dataGSA, setDataGSA] = useState({
        order1: [0],
        order_total: [0],
        categories: ["empty data"],
    })
    const [xlabelGSA, setXlabelGSA] = useState("x")
    const optionsGSA = plotInitGSA(dataGSA,xlabelGSA);

    // add points
    // errorbar in x direction does not exist in highcharts therefore using line
    // simpler to add invisible error bar in each case and then only process visible "error bars"

    const initx1 = 0.0;
    const inity1 = 20.0;
    const initP1 = [{ x: initx1, y: inity1 }];
    const initXBoundP1 = [{x:initx1-15, y:inity1},{x:initx1, y:inity1},{x:initx1+15, y:inity1}];
    const initYBoundP1 = [{x:initx1, y:inity1-30},{x:initx1, y:inity1},{x:initx1, y:inity1+30}];
    const [options, setOptions] = useState(plotInit(initChartClick, initPointClick, pointDrag, releaseBounds,
        initP1, initXBoundP1, initYBoundP1, chartRef, handleContextMenu, hideContextMenu, settData, setTData));
    
    

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
        setDiffusionModel(diffModelType)
    };

        return (
            <div id='testing2' onClick={handleNonchartClick}>
            <div>
            { menu ? <Menu 
            xPos={xPos} yPos={yPos} 
            chartRef={chartRef} indPoint={indPoint} maxChecked={maxChecked} 
            tData={tData} TData={TData} settData={settData} setTData={setTData}
            handleTimeSelectMenu={handleTimeSelectMenu} handleTemperatureSelectMenu={handleTemperatureSelectMenu}
            /> : null }
            </div>
                <div>
                    <HighchartsReact
                        highcharts={Highcharts}
                        options={options}
                        ref={chartRef}
                    />
                </div>
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
                        onChange={(e) => setRadioValue(e.currentTarget.value)}>
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
                { (diffusionModel==="flowers09") ?
                    <Diff chartRef={chartRef} tData={tData} TData={TData} checkedList={checkedList} maxChecked={maxChecked} onCheckChange={(e)=>handleCheckFlowers09(e,tData,TData,settData,setTData,setMaxChecked,checkedList, setCheckedList)} 
                        setIsChartXY={setIsChartXY} setDataXY={setDataXY} setXlabelXY={setXlabelXY}
                        setIsChartGSA={setIsChartGSA} setDataGSA={setDataGSA} setXlabelGSA={setXlabelGSA}
                        radioValue={radioValue} diffusionModel={diffusionModel}
                    />
                : null}
                { (diffusionModel==="cherniak00") ?
                    <div>TODO: cherniak, 2000 U-Pb</div>
                : null}
                <br></br>
                </div>                
                <br></br>
                { (tData.length>0) &&
                <TimeDataCheckList tData={tData} TData={TData} settData={settData} setTData={setTData} checkedList={checkedList} setMaxChecked={setMaxChecked} chartRef={chartRef}/>}
                { (TData.length>0) &&
                <TempDataCheckList tData={tData} TData={TData} settData={settData} setTData={setTData} checkedList={checkedList} setMaxChecked={setMaxChecked} chartRef={chartRef}/>}
                { (isChartXY===true) &&
                    <HighchartsReact
                        highcharts={Highcharts}
                        options={optionsXY}
                />}
                { (isChartGSA===true) &&
                    <HighchartsReact
                        highcharts={Highcharts}
                        options={optionsGSA}
                />}
            </div>
        );  
}