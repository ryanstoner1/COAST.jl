import vert from './vert.svg'
import horiz from './horiz.svg'

const Menu = ({xPos, yPos, timeContextMenu, temperatureContextMenu}) => {

    return (
      <ul className="menu" style={{ top: yPos, left: xPos }}>
        <li onClick={timeContextMenu}>
            <div className='container'>
                <span id="a">
                    toggle time bounds (Ma) 
                </span>
                <img src={horiz} alt='' width='35px'  id="b"></img>
            </div>
        </li>
        <li onClick={temperatureContextMenu}>
            <div className="container">
                <span id="c">toggle temperature bounds (ºC) </span>
                <img src={vert} alt='' width='35px' id="d"></img>
            </div>
        </li>
     </ul>
    );
  
};

export default Menu
