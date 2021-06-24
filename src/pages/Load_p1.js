import axios from 'axios';
import {React, useState } from 'react';
import {Form, Dropdown, DropdownButton} from 'react-bootstrap';
function Load() {
  const [dataHefty, setDataHefty] = useState({});

  const handleInput = (e) =>{
    console.log(e.target.files[0])
    const formData = new FormData();

    formData.append("file", e.target.files[0]);   
  axios
    .post("http://127.0.0.1:5000/getfile", formData)
    .then(res => setDataHefty(res))
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
  { (Object.keys(dataHefty).length) ? 
    <div>
        <DropdownButton id="dropdown-basic-button" title="Processing options">
        <Dropdown.Item href="#/action-1">Plot Data</Dropdown.Item>
        <Dropdown.Item href="#/action-2">Subsample Data</Dropdown.Item>
        <Dropdown.Item href="#/action-3">Sensitivity Analysis</Dropdown.Item>
        </DropdownButton>
    </div> : null}
  </div>);
}

export default Load