import React, { useRef } from "react";

import Menu from "./Menu";

const Table = () => {
  const outerRef = useRef(null);
  const outerRef3 = useRef(null);
  return (
    <div className="table-container">
      <Menu outerRef={outerRef} />
      <p>Dostojnost je jednou z najpoprednejsich sil cloveka</p>
      <table ref={outerRef}>
        <tbody ref={outerRef}>
          <tr id="row1">
            <td>
              <input type="checkbox" />
            </td>
            <td>Smbc</td>
            <td>20</td>
          </tr>
        </tbody>
      </table>
      <Menu outerRef={outerRef3} />
      <span ref={outerRef3}>value</span>
    </div>
    

  );
};

export default Table;
