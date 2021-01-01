#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Dec 30 16:38:11 2020

@author: ryanstoner
"""
import streamlit as st
from SessionState import get

session_state = get(password='')
def main():
    st.title("hey")
    uploaded_files = st.file_uploader("Choose a CSV file")
    return 

if session_state.password != 'pwd123':
    pwd_placeholder = st.sidebar.empty()
    pwd = pwd_placeholder.text_input("Password:", value="", type="password")
    session_state.password = pwd
    if session_state.password == 'pwd123':
        pwd_placeholder.empty()
        main()
    elif session_state.password != '':
        st.error("the password you entered is incorrect")
else:
    main()