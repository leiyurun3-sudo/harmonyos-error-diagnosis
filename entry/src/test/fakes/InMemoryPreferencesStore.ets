import {
  PreferenceValue,
  PreferencesStore
} from '../../main/ets/storage/preferences/PreferencesStore';

interface PreferenceEntry {
  key: string;
  value: PreferenceValue;
}

/** Shared test backend used to simulate persistence across store instances. */
export class InMemoryPreferencesState {
  entries: Array<PreferenceEntry> = [];
}

export class InMemoryPreferencesStore implements PreferencesStore {
  private state: InMemoryPreferencesState;
  private readFailure: boolean;
  private writeFailure: boolean;

  constructor(
    state: InMemoryPreferencesState,
    readFailure: boolean = false,
    writeFailure: boolean = false
  ) {
    this.state = state;
    this.readFailure = readFailure;
    this.writeFailure = writeFailure;
  }

  read(key: string, defaultValue: PreferenceValue): Promise<PreferenceValue> {
    if (this.readFailure) {
      return Promise.reject(new Error('Synthetic preferences read failure'));
    }
    for (let index: number = 0; index < this.state.entries.length; index++) {
      if (this.state.entries[index].key === key) {
        return Promise.resolve(this.state.entries[index].value);
      }
    }
    return Promise.resolve(defaultValue);
  }

  write(key: string, value: PreferenceValue): Promise<void> {
    if (this.writeFailure) {
      return Promise.reject(new Error('Synthetic preferences write failure'));
    }
    for (let index: number = 0; index < this.state.entries.length; index++) {
      if (this.state.entries[index].key === key) {
        this.state.entries[index].value = value;
        return Promise.resolve();
      }
    }
    this.state.entries.push({ key: key, value: value });
    return Promise.resolve();
  }

  flush(): Promise<void> {
    if (this.writeFailure) {
      return Promise.reject(new Error('Synthetic preferences flush failure'));
    }
    return Promise.resolve();
  }

  seed(key: string, value: PreferenceValue): void {
    for (let index: number = 0; index < this.state.entries.length; index++) {
      if (this.state.entries[index].key === key) {
        this.state.entries[index].value = value;
        return;
      }
    }
    this.state.entries.push({ key: key, value: value });
  }

  valueOf(key: string): PreferenceValue | undefined {
    for (let index: number = 0; index < this.state.entries.length; index++) {
      if (this.state.entries[index].key === key) {
        return this.state.entries[index].value;
      }
    }
    return undefined;
  }
}
