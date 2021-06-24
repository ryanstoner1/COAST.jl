import React from 'react';
import './App.css';
import {
  BrowserRouter as Router,
  NavLink,
  Route
} from "react-router-dom";
import { Navbar, Nav, NavDropdown } from 'react-bootstrap';  
import Load from './pages/Load_p1.js'
import About from './pages/About_p2.js'
import Forward from './pages/Forward_p3.js'

import 'bootstrap/dist/css/bootstrap.min.css';
function App() {
  return (
<Router>
  <Navbar bg="light" expand="lg" style={{paddingLeft: "2em"}}>
  <Navbar.Brand as={NavLink} to="/"> COAST</Navbar.Brand>
  <Navbar.Toggle aria-controls="responsive-navbar-nav" />
  <Navbar.Collapse id="responsive-navbar-nav">
    <Nav>
      <Nav.Link as={NavLink} to="/">About</Nav.Link>
      <Nav.Link as={NavLink} to="/load" exact>Load</Nav.Link>      
      <NavDropdown title="Sensitivity Analysis" id="collasible-nav-dropdown">
        <NavDropdown.Item as={NavLink} to="/forward">Forward</NavDropdown.Item>
        <NavDropdown.Item href="#action/3.2">Inverse</NavDropdown.Item>
        <NavDropdown.Item href="#action/3.3">Something</NavDropdown.Item>
        <NavDropdown.Divider />
        <NavDropdown.Item href="#action/3.4">Separated link</NavDropdown.Item>
      </NavDropdown>
    </Nav>
  </Navbar.Collapse>
</Navbar>
<Route path="/" exact component={About} />
<Route path="/load" exact component={Load} />
<Route path="/forward" exact component={Forward} />
</Router>
	);
}


 
export default App;
