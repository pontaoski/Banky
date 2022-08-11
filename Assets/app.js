import './app.css'

import { Application } from "@hotwired/stimulus"
import { registerControllers } from 'stimulus-vite-helpers'
import * as Turbo from "@hotwired/turbo"

const application = window.Stimulus = Application.start()
const controllers = import.meta.globEager('./**/*_controller.ts')
registerControllers(application, controllers)
