import React from "react";
import vert from './vert.svg'
import horiz from './horiz.svg'
import useContextMenu from "./useContextMenu";

/**
 * Menu creates a new context menu
 */
const Menu = ({ outerRef }) => {
  
  const { xPos, yPos, menu} = useContextMenu(outerRef);

    if (menu) {
    return (
      <ul className="menu" style={{ top: yPos, left: xPos }}>
        <li>
            <div className='container'>
                <span id="a">
                    set time range (Ma) 
                </span>
                <img src={horiz} alt='' width='35px'  id="b"></img>
            </div>
        </li>
        <li><div className="container"><span id="c">set temperature range (C) </span><img src={vert} alt='' width='35px' id="d"></img></div></li>
     </ul>
    );
  }
  return <div></div>;
};

export default Menu;
