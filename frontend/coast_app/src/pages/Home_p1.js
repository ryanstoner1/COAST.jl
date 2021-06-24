import React from 'react';
import {Form, FormControl} from 'react-bootstrap';
function Load() {
  const handleInput = (e) =>{
    console.log(e)
  };
  return (<div><Form>
    <Form.File 
      id="custom-file"
      label="Custom file input"
      onInput={handleInput}
    />
  </Form>
  </div>);
}

export default Load