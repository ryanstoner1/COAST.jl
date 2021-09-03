import axios from 'axios';
import plotHeFTy from './plotHeFTy_p1.js'
import Highcharts from 'highcharts/highstock';
import HighchartsReact from 'highcharts-react-official';
import {React, useState, useRef, useEffect, useCallback } from 'react';
import {InputGroup, FormControl, Form, Dropdown, DropdownButton, ButtonGroup, ToggleButton} from 'react-bootstrap';
import plotInit from './plotInit_p3.js'
import initChartClick from './initChartClick.js';
import initPointClick from './initPointClick.js';
import pointDrag from './pointDrag.js'
import Menu from './Menu_p3.js'
import { timeContextMenu, temperatureContextMenu } from './contextMenu.js';
require('highcharts/highcharts-more')(Highcharts);
require("highcharts/modules/draggable-points")(Highcharts);

function Load() {
  const chartRefInit = useRef(null); 
  const chartRefPlot = useRef(null); 
  const [radioValue, setRadioValue] = useState('1');
  const [areManySeries, setAreManySeries] = useState(false);
  const [nPointsSens, setNPointsSens] = useState('');
  const [optionsPlot, setOptionsPlot] = useState({});
  const [loadMessage, setLoadMessage] = useState(null);
  const [optionsHeFTy, setOptionsHeFTy] = useState({});
  const [topBoundGood, setTopBoundGood] = useState([]);
  const [botBoundGood, setBotBoundGood] = useState([]);
  const [timeBoundGood, setTimeBoundGood] = useState([]);
  const [topBoundAcc, setTopBoundAcc] = useState([]);
  const [botBoundAcc, setBotBoundAcc] = useState([]);
  const [timeBoundAcc, setTimeBoundAcc] = useState([]);
  const [optionsSens, setOptionsSens] = useState({});
  const [maxChecked, setMaxChecked] = useState(false)

  const [xData,setXData] = useState([]);
  const [yData,setYData] = useState([]);
  const [xPos, setXPos] = useState("0px");
  const [yPos, setYPos] = useState("0px");
  const [menu, showMenu] = useState(false);
  const [indPoint, setIndPoint] = useState(null);

  const radios = [
    { name: 'Acceptable', value: '1' },
    { name: 'Good', value: '2' },
  ];


  const handleInput = (e) =>{
    console.log(e.target.files[0])
    const formData = new FormData();

    formData.append("file", e.target.files[0]);
    setLoadMessage("Processing data . . . (this may take a minute or two)")   
  axios
    .post("http://127.0.0.1:5000/getfile", formData)
    .then(
      res => {
        console.log(res.data)
        
        setTopBoundGood(res.data.good_hi)
        setBotBoundGood(res.data.good_lo)
        setTopBoundAcc(res.data.acc_hi)
        setBotBoundAcc(res.data.acc_lo) 
        setTimeBoundAcc(res.data.acc_time)
        setTimeBoundGood(res.data.good_time)        
        const valToPlot = res.data.t_Ma.map((element1, index1) => {
          return {
            index: -index1,
            opacity: (res.data.tT_names[index1][1]==="good")? 0.55 : 0.12,
            color: (res.data.tT_names[index1][1]==="good")? "#1F83A0" : "#3C8B65",
            showInLegend: false,
            data: element1.map((element2, index2) => {
             return {x: element2, y: res.data.T_celsius[index1][index2]}
             })}
        }
      )

      const outOptions = plotHeFTy(res.data.max_time, res.data.max_temp, valToPlot);
      setOptionsHeFTy(outOptions);
      setLoadMessage("Processed!")
      })
    .catch(err => console.warn(err))
  };

  const handlePlot = (optionsHeFTy,chartRefInit,topBoundGood,botBoundGood,timeBoundGood, topBoundAcc,botBoundAcc,timeBoundAcc) => {

    const limitSeries = 800; // past this there is significant lag; works up to at least 5000 though
    if (optionsHeFTy.series.length<limitSeries) {
      setOptionsPlot(optionsHeFTy)
      setAreManySeries(false)
    } else {     
      const optionsHeFTyCull = JSON.parse(JSON.stringify(optionsHeFTy));      
      optionsHeFTyCull.series.length = limitSeries;
      setOptionsPlot(optionsHeFTyCull)
      setAreManySeries(true)
    }
  };

  // need to interpolate; usually time bounds have more points than needed
  const handleSensitivity = (timeBoundAcc, botBoundAcc, topBoundAcc, timeBoundGood, botBoundGood, topBoundGood, nPointsSens, radioValue) => {
    console.log(timeBoundAcc)
    console.log(radioValue)
    const formData = new FormData();
    const formNPoints = {};
    formNPoints.nPoints = nPointsSens;

    // if good or acc selected
    if (radioValue===1) {
      formNPoints.botBound = botBoundAcc; 
      formNPoints.topBound = topBoundAcc; 
      formNPoints.timeBound = timeBoundAcc; 
    } else {
      formNPoints.botBound = botBoundGood; 
      formNPoints.topBound = topBoundGood; 
      formNPoints.timeBound = timeBoundGood; 
    };


    formData.append("npoints",JSON.stringify(formNPoints)); 
    const config = {     
      headers: { 'content-type': 'application/json' }
    }
    axios.post("http://127.0.0.1:5000/getNBounds",formData, config).then(res=> {
                        console.log(res)
                        const initx1 = 10.0;
                        const inity1 = 20.0;
                        const initP1 = [{ x: initx1, y: inity1 }];
                        const initXBoundP1 = [{x:initx1-15, y:inity1},{x:initx1, y:inity1},{x:initx1+15, y:inity1}];
                        const initYBoundP1 = [{x:initx1, y:inity1-30},{x:initx1, y:inity1},{x:initx1, y:inity1+30}];
                        // res.data.bot
                        const optionsRes = plotInit(initChartClick, initPointClick, pointDrag, initP1, 
                          initXBoundP1, initYBoundP1, chartRefPlot, handleContextMenu, 
                          hideContextMenu, setXData, setYData)
                        setOptionsSens(optionsRes)
                    }).catch(err => console.warn(err));   
  };

  useEffect(() => {
    console.log(timeBoundAcc)
    if (chartRefInit.current && areManySeries && timeBoundAcc.length && botBoundAcc && topBoundAcc)  {
      console.log("many series regime")
      console.log(timeBoundAcc)
      const topBoundAccPlot = timeBoundAcc.map(
        (elem, index) => {
          return {x: elem, y: topBoundAcc[index]}
        }
      );
      const botBoundAccPlot = timeBoundAcc.map(
        (elem, index) => {
          return {x: elem, y: botBoundAcc[index]}
        }
      );
      chartRefInit.current.chart.addSeries({name: "lower acc. bound", color: "#000000", opacity: 1.0, data: topBoundAccPlot});
      chartRefInit.current.chart.addSeries({name: "upper acc. bound", color: "#000000",  opacity: 1.0, data: botBoundAccPlot});
    }
  },[chartRefInit, timeBoundAcc, topBoundAcc, botBoundAcc, areManySeries]);

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

  return (<div>
    <br></br>
    <p>Load HeFTy file: </p>
    <div>
    </div>
    <Form>
    <Form.File 
      id="custom-file"
      label=""
      onInput={handleInput}
    />
  </Form>
  <br></br>
  { (loadMessage) ?
<div>
{loadMessage}
</div> : null}
  <br></br>
  { (Object.keys(optionsHeFTy).length) ? 
    <div>
        <DropdownButton id="dropdown-basic-button" title="Processing options">
        <Dropdown.Item href="#/action-1" onClick={() => handlePlot(optionsHeFTy,chartRefInit, topBoundGood,botBoundGood,timeBoundGood, topBoundAcc,botBoundAcc, timeBoundAcc)}>Plot Data</Dropdown.Item>
        <Dropdown.Item href="#/action-2">Subsample Data</Dropdown.Item>
        <Dropdown.Item onClick={() => handleSensitivity(timeBoundAcc, botBoundAcc, topBoundAcc, timeBoundGood, botBoundGood, topBoundGood, nPointsSens, radioValue)}>Sensitivity Analysis</Dropdown.Item>
        </DropdownButton>
    </div> : null}
  { (Object.keys(optionsPlot).length) ?
  <div>
    <HighchartsReact
      highcharts={Highcharts}
      options={optionsPlot}
      ref={chartRefInit}
    />
    <InputGroup className="mb-3">
    <InputGroup.Prepend>
    <InputGroup.Text id="inputGroup-d0">Number of time segments for sensitivity analysis?<div>&nbsp;</div><input type="checkbox"   value="c3Value"/></InputGroup.Text>
    </InputGroup.Prepend>
    <FormControl aria-label="Text input with checkbox" placeholder="number" value={nPointsSens} onInput={e => setNPointsSens(e.target.value)}/>
    </InputGroup>
    <InputGroup className="mb-3">
    </InputGroup>
    <br />
      <ButtonGroup className="mb-2">
        {radios.map((radio, idx) => (
          <ToggleButton
            key={idx}
            id={`radio-${idx}`}
            type="radio"
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
      <br />
  </div> : null}
{ menu ? <Menu 
            xPos={xPos} yPos={yPos} 
            chartRef={chartRefPlot} indPoint={indPoint} maxChecked={maxChecked} 
            xData={xData} yData={yData} setXData={setXData} setYData={setYData}
            timeContextMenu={timeContextMenu} temperatureContextMenu={temperatureContextMenu}
            /> : null }
{Object.keys(optionsSens).length === 0 ? null: 
<div>                
    <div>
      <HighchartsReact
          highcharts={Highcharts}
          options={optionsSens}
          ref={chartRefPlot}
      />
    </div>
</div> }
</div>);
}

export default Load