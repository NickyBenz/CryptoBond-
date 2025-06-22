import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'
import HomePage from "./components/HomePage.jsx"
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Dashboard from './components/Dashboard.jsx'
import ErrorPage from './components/ErrorPage.jsx'
function App() {

  return(
    <Routes>
      <Route path="*" element={<HomePage />} />
      <Route path="/dashboard" element={<Dashboard />} />
      <Route path="/error" element={<ErrorPage></ErrorPage>}/> 
    </Routes>
  )
  
}

export default App
