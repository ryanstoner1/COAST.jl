import vert from './vert.svg'
import horiz from './horiz.svg'

// Menu creates menu of to specify whether temperature or time are used for sensitivity analysis 
const Menu = ({xPos,yPos,
    chartRef,indPoint,maxChecked,
    tData,TData,settData,setTData,
    handleTimeSelectMenu, handleTemperatureSelectMenu}) => {
    const xPosRaw = xPos.slice(0,xPos.length-2);
    const xPosNew = parseInt(xPosRaw) + 10;
    const yPosRaw = yPos.slice(0,yPos.length-2);
    const yPosNew = parseInt(yPosRaw) - 3;
    return (
      <ul className="menu" style={{ top: yPosNew, left: xPosNew }}>
        <li onClick={()=>handleTimeSelectMenu(chartRef, indPoint, maxChecked, tData, settData)}>
            <div className='container'>
                <span id="a">
                    toggle time bounds (Ma) 
                </span>
                <img src={horiz} alt='' width='30px'  id="b"></img>
            </div>
        </li>
        <li onClick={()=>handleTemperatureSelectMenu(chartRef, indPoint, maxChecked, TData, setTData)}>
            <div className="container">
                <span id="c">toggle temperature bounds (ºC) </span>
                <img src={vert} alt='' width='30px' id="d"></img>
            </div>
        </li>
     </ul>
    ); 
};

export default Menu
