import { createApp } from 'vue'
import ViewUIPlus from 'view-ui-plus'
import App from './App.vue'
import 'view-ui-plus/dist/styles/viewuiplus.css'

createApp(App)
.use(ViewUIPlus)
.mount('#app')
