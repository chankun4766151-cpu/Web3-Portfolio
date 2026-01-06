import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import AppProvider from './AppProvider.tsx'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AppProvider />
  </StrictMode>,
)
