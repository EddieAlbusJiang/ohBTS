import { DisplayMode } from './Types';
import preferences from '@ohos.data.preferences';

export class SettingsManager {
  private static instance: SettingsManager;
  private static readonly PREF_NAME = 'bluetooth_remote_settings';
  
  private _displayMode: DisplayMode = DisplayMode.ASCII;
  private _autoResendInterval: number = 50;
  private preferences: preferences.Preferences | null = null;
  
  private onSettingsChange?: () => void;
  
  private constructor() {}
  
  static getInstance(): SettingsManager {
    if (!SettingsManager.instance) {
      SettingsManager.instance = new SettingsManager();
    }
    return SettingsManager.instance;
  }
  
  get displayMode(): DisplayMode {
    return this._displayMode;
  }
  
  set displayMode(mode: DisplayMode) {
    this._displayMode = mode;
    this.saveSettings();
    if (this.onSettingsChange) {
      this.onSettingsChange();
    }
  }
  
  get autoResendInterval(): number {
    return this._autoResendInterval;
  }
  
  set autoResendInterval(value: number) {
    if (value < 0) {
      value = 0;
    }
    this._autoResendInterval = value;
    this.saveSettings();
    if (this.onSettingsChange) {
      this.onSettingsChange();
    }
  }
  
  setOnSettingsChange(callback: () => void) {
    this.onSettingsChange = callback;
  }
  
  async initialize(context: Context): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(context, SettingsManager.PREF_NAME);
      await this.loadSettings();
    } catch (error) {
      console.error('Settings initialization failed:', error);
    }
  }
  
  private async loadSettings(): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      const modeStr = await this.preferences.get('displayMode', DisplayMode.ASCII) as string;
      this._displayMode = modeStr === DisplayMode.HEX ? DisplayMode.HEX : DisplayMode.ASCII;
      
      const intervalVal = await this.preferences.get('autoResendInterval', 50);
      if (typeof intervalVal === 'number') {
        this._autoResendInterval = intervalVal;
      } else if (typeof intervalVal === 'string') {
        const parsed = parseInt(intervalVal);
        this._autoResendInterval = isNaN(parsed) ? 50 : parsed;
      }
    } catch (error) {
      console.error('Load settings failed:', error);
    }
  }
  
  private async saveSettings(): Promise<void> {
    if (!this.preferences) {
      return;
    }
    
    try {
      await this.preferences.put('displayMode', this._displayMode);
      await this.preferences.put('autoResendInterval', this._autoResendInterval);
      await this.preferences.flush();
    } catch (error) {
      console.error('Save settings failed:', error);
    }
  }
}
