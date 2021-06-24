import React from 'react';

function About() {
  return (
  <div style={{paddingLeft: "2em"}}>
      <br></br>
      <br></br>
      <h4>Constrained Optimization and Sensitivity for Thermochronology (COAST)</h4>
      <br></br>
      <h4>Motivation</h4>
      <br></br>
      <p>
      Unfortunately, we often only know the relative contributions of each of these sources of uncertainty qualitatively. 
      Quantifying relative contributions of error is currently very computationally challenging with existing methods. 
      The following questions are computationally challenging to answer quantitatively:
      </p>
      <i>How much of my uncertainty is because our problem is underconstrained?</i>
      <br></br>
      <i>How does uncertainty in my diffusion or radiation damage model affect my thermal histories?</i>
      <br></br>
      <br></br>
      <h4>About this package</h4>
      <br></br>
      <p>The inputs in this package are the same as existing thermochronology software packages for thermal history.</p>
      <p>However, the primary goals are to:</p>
      <ul>
          <li>Determine the importance of inputs</li>
          <li>Rank inputs qualitatively</li>
          <li>Quantitatively compare input variance</li>
      </ul>
  </div>);
} 

export default About