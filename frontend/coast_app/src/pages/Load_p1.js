import axios from 'axios';
import plotHeFTy from './plotHeFTy_p1.js'
import Highcharts from 'highcharts/highcharts';
import HighchartsReact from 'highcharts-react-official';
import {React, useState } from 'react';
import {Form, Dropdown, DropdownButton} from 'react-bootstrap';
function Load() {
  const [optionsHeFTy, setOptionsHeFTy] = useState({});

  const handleInput = (e) =>{
    console.log(e.target.files[0])
    const formData = new FormData();

    formData.append("file", e.target.files[0]);   
  axios
    .post("http://127.0.0.1:5000/getfile", formData)
    .then(
      res => {
        console.log(res.data)
        const valToPlot = res.data.t_Ma.map((element1, index1) => {
          return {
            opacity: (res.data.tT_names[index1][1]==="good")? 0.55 : 0.12,
            color: (res.data.tT_names[index1][1]==="good")? "#1F83A0" : "#3C8B65",
            showInLegend: false,
            data: element1.map((element2, index2) => {
             return {x: element2, y: res.data.T_celsius[index1][index2]}
             })}
        }
      )

      const outOptions = plotHeFTy(res.data.max_time, res.data.max_temp, valToPlot)
      console.log(outOptions)
      setOptionsHeFTy(outOptions)
      })
    .catch(err => console.warn(err))
  }
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
  { (Object.keys(optionsHeFTy).length) ? 
    <div>
        <DropdownButton id="dropdown-basic-button" title="Processing options">
        <Dropdown.Item href="#/action-1">Plot Data</Dropdown.Item>
        <Dropdown.Item href="#/action-2">Subsample Data</Dropdown.Item>
        <Dropdown.Item href="#/action-3">Sensitivity Analysis</Dropdown.Item>
        </DropdownButton>
    </div> : null}
  { (Object.keys(optionsHeFTy).length) ?
  <div>
    <HighchartsReact
      highcharts={Highcharts}
      options={optionsHeFTy}
    />
  </div> : null}
  </div>);
}

export default Load