# kenzi-ai-capacitor-google-navigation

Capacitor Google Navigation SDK, powered by kenzi.ai

for help and support please contact us at connect@kenzi.ai

## Install

```bash
npm install kenzi-ai-capacitor-google-navigation
npx cap sync
```

## API

<docgen-index>

* [`initialize(...)`](#initialize)
* [`startNavigation(...)`](#startnavigation)
* [`addListener('navigationClosed', ...)`](#addlistenernavigationclosed-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### initialize(...)

```typescript
initialize(options?: InitOptions | undefined) => Promise<{ ok: boolean; }>
```

| Param         | Type                                                |
| ------------- | --------------------------------------------------- |
| **`options`** | <code><a href="#initoptions">InitOptions</a></code> |

**Returns:** <code>Promise&lt;{ ok: boolean; }&gt;</code>

--------------------


### startNavigation(...)

```typescript
startNavigation(options: StartOptions) => Promise<{ started: boolean; }>
```

| Param         | Type                                                  |
| ------------- | ----------------------------------------------------- |
| **`options`** | <code><a href="#startoptions">StartOptions</a></code> |

**Returns:** <code>Promise&lt;{ started: boolean; }&gt;</code>

--------------------


### addListener('navigationClosed', ...)

```typescript
addListener(eventName: 'navigationClosed', listenerFunc: (data: { closed: true; }) => void) => Promise<PluginListenerHandle>
```

| Param              | Type                                              |
| ------------------ | ------------------------------------------------- |
| **`eventName`**    | <code>'navigationClosed'</code>                   |
| **`listenerFunc`** | <code>(data: { closed: true; }) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

--------------------


### Interfaces


#### InitOptions

| Prop            | Type                | Description                                        |
| --------------- | ------------------- | -------------------------------------------------- |
| **`iosApiKey`** | <code>string</code> | iOS only (Android reads key from AndroidManifest). |


#### StartOptions

| Prop            | Type                    | Description               |
| --------------- | ----------------------- | ------------------------- |
| **`originLat`** | <code>number</code>     |                           |
| **`originLng`** | <code>number</code>     |                           |
| **`destLat`**   | <code>number</code>     |                           |
| **`destLng`**   | <code>number</code>     |                           |
| **`waypoints`** | <code>Waypoint[]</code> |                           |
| **`simulate`**  | <code>boolean</code>    |                           |
| **`title`**     | <code>string</code>     | Android-only header title |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


### Type Aliases


#### Waypoint

<code>{ lat: number; lng: number }</code>

</docgen-api>
