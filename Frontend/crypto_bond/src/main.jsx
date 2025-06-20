import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import { createBrowserRouter, BrowserRouter, RouterProvider } from 'react-router-dom'
import HomePage from './components/HomePage.jsx'
import Dashboard from './components/Dashboard.jsx'

const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
      {
        index: true,
        element: <HomePage />
      },
      {
        path: 'dashboard',
        element: <Dashboard />
      }
    ]
  } 
])




createRoot(document.getElementById('root')).render(
  <StrictMode>
        <BrowserRouter>
          <App></App>
            </BrowserRouter>

  </StrictMode>,
)
