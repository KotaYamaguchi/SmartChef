
# Framework

Foundation Models
Perform tasks with the on-device model that specializes in language understanding, structured output, and tool calling.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

## Overview

The Foundation Models framework provides access to Apple’s on-device large language model that powers Apple Intelligence to help you perform intelligent tasks specific to your use case. The text-based on-device model identifies patterns that allow for generating new text that’s appropriate for the request you make, and it can make decisions to call code you write to perform specialized tasks.
￼
Generate text content based on requests you make. The on-device model excels at a diverse range of text generation tasks, like summarization, entity extraction, text understanding, refinement, dialog for games, generating creative content, and more.
Generate entire Swift data structures with guided generation. With the @Generable macro, you can define custom data structures and the framework provides strong guarantees that the model generates instances of your type.
To expand what the on-device foundation model can do, use Tool to create custom tools that the model can call to assist with handling your request. For example, the model can call a tool that searches a local or online database for information, or calls a service in your app.
To use the on-device language model, people need to turn on Apple Intelligence on their device. For a list of supported devices, see Apple Intelligence.
For more information about acceptable usage of the Foundation Models framework, see Acceptable use requirements for the Foundation Models framework.
Related videos
￼
Meet the Foundation Models framework
￼
Deep dive into the Foundation Models framework
￼
Code-along: Bring on-device AI to your app using the Foundation Models framework

## Topics

Essentials

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
struct UseCase
```
A type that represents the use case for prompting.
Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.
Guided generation

Generating Swift data structures with guided generation
Create robust apps by describing output you want programmatically.

```swift
protocol Generable
```
A type that the model uses when responding to prompts.
Tool calling

Expanding generation with tool calling
Build tools that enable the model to perform tasks that are specific to your use case.

Generate dynamic game content with guided generation and tools
Make gameplay more lively with AI generated dialog and encounters personalized to the player.

```swift
protocol Tool
```
A tool that a model can call to gather information at runtime or perform side effects.
Feedback

```swift
struct LanguageModelFeedback
```
Feedback appropriate for logging or attaching to Feedback Assistant.


# Article

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

## Overview

The Foundation Models framework lets you tap into the on-device large models at the core of Apple Intelligence. You can enhance your app by using generative models to create content or perform tasks. The framework supports language understanding and generation based on model capabilities.
For design guidance, see Human Interface Guidelines > Technologies > Generative AI.
Understand model capabilities
When considering features for your app, it helps to know what the on-device language model can do. The on-device model supports text generation and understanding that you can use to:
Capability
Prompt example
Summarize
“Summarize this article.”
Extract entities
“List the people and places mentioned in this text.”
Understand text
“What happens to the dog in this story?”
Refine or edit text
“Change this story to be in second person.”
Classify or judge text
“Is this text relevant to the topic ‘Swift’?”
Compose creative writing
“Generate a short bedtime story about a fox.”
Generate tags from text
“Provide two tags that describe the main topics of this text.”
Generate game dialog
“Respond in the voice of a friendly inn keeper.”
The on-device language model may not be suitable for handling all requests, like:
Capabilities to avoid
Prompt example
Do basic math
“How many b’s are there in bagel?”
Create code
“Generate a Swift navigation list.”
Perform logical reasoning
“If I’m at Apple Park facing Canada, what direction is Texas?”
The model can complete complex generative tasks when you use guided generation or tool calling. For more on handling complex tasks, or tasks that require extensive world-knowledge, see Generating Swift data structures with guided generation and Expanding generation with tool calling.
Check for availability
Before you use the on-device model in your app, check that the model is available by creating an instance of SystemLanguageModel with the default property.
Model availability depends on device factors like:
- The device must support Apple Intelligence.
- The device must have Apple Intelligence turned on in Settings.
Note
It can take some time for the model to download and become available when a person turns on Apple Intelligence.
Always verify model availability first, and plan for a fallback experience in case the model is unavailable.

```swift
struct GenerativeView: View {
    // Create a reference to the system language model.
    private var model = SystemLanguageModel.default


    var body: some View {
        switch model.availability {
        case .available:
            // Show your intelligence UI.
        case .unavailable(.deviceNotEligible):
            // Show an alternative UI.
        case .unavailable(.appleIntelligenceNotEnabled):
            // Ask the person to turn on Apple Intelligence.
        case .unavailable(.modelNotReady):
            // The model isn't ready because it's downloading or because of other system reasons.
        case .unavailable(let other):
            // The model is unavailable for an unknown reason.
        }
    }
}
```
Create a session
After confirming that the model is available, create a LanguageModelSession object to call the model. For a single-turn interaction, create a new session each time you call the model:
// Create a session with the system model.

```swift
let session = LanguageModelSession()
```
For a multiturn interaction — where the model retains some knowledge of what it produced — reuse the same session each time you call the model.
Provide a prompt to the model
A Prompt is an input that the model responds to. Prompt engineering is the art of designing high-quality prompts so that the model generates a best possible response for the request you make. A prompt can be as short as “hello”, or as long as multiple paragraphs. The process of designing a prompt involves a lot of exploration to discover the best prompt, and involves optimizing prompt length and writing style.
When thinking about the prompt you want to use in your app, consider using conversational language in the form of a question or command. For example, “What’s a good month to visit Paris?” or “Generate a food truck menu.”
Write prompts that focus on a single and specific task, like “Write a profile for the dog breed Siberian Husky”. When a prompt is long and complicated, the model takes longer to respond, and may respond in unpredictable ways. If you have a complex generation task in mind, break the task down into a series of specific prompts.
You can refine your prompt by telling the model exactly how much content it should generate. A prompt like, “Write a profile for the dog breed Siberian Husky” often takes a long time to process as the model generates a full multi-paragraph essay. If you specify “using three sentences”, it speeds up processing and generates a concise summary. Use phrases like “in a single sentence” or “in a few words” to shorten the generation time and produce shorter text.
// Generate a longer response for a specific command.

```swift
let simple = "Write me a story about pears."


```
// Quickly generate a concise response.

```swift
let quick = "Write the profile for the dog breed Siberian Husky using three sentences."
```
Provide instructions to the model
Instructions help steer the model in a way that fits the use case of your app. The model obeys prompts at a lower priority than the instructions you provide. When you provide instructions to the model, consider specifying details like:
- What the model’s role is; for example, “You are a mentor,” or “You are a movie critic”.
- What the model should do, like “Help the person extract calendar events,” or “Help the person by recommending search suggestions”.
- What the style preferences are, like “Respond as briefly as possible”.
- What the possible safety measures are, like “Respond with ‘I can’t help with that’ if you’re asked to do something dangerous”.
Use content you trust in instructions because the model follows them more closely than the prompt itself. When you initialize a session with instructions, it affects all prompts the model responds to in that session. Instructions can also include example responses to help steer the model. When you add examples to your prompt, you provide the model with a template that shows the model what a good response looks like.
Generate a response
To call the model with a prompt, call respond(to:options:) on your session. The response call is asynchronous because it may take a few seconds for the on-device foundation model to generate the response.

```swift
let instructions = """
    Suggest five related topics. Keep them concise (three to seven words) and make sure they \
    build naturally from the person's topic.
    """


let session = LanguageModelSession(instructions: instructions)


let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)
```
Note
A session can only handle a single request at a time, and causes a runtime error if you call it again before the previous request finishes. Check isResponding to verify the session is done processing the previous request before sending a new one.
Instead of working with raw string output from the model, the framework offers guided generation to generate a custom Swift data structure you define. For more information about guided generation, see Generating Swift data structures with guided generation.
When you make a request to the model, you can provide custom tools to help the model complete the request. If the model determines that a Tool can assist with the request, the framework calls your Tool to perform additional actions like retrieving content from your local database. For more information about tool calling, see Expanding generation with tool calling
Consider context size limits per session
The context window size is a limit on how much data the model can process for a session instance. A token is a chunk of text the model processes, and the system model supports up to 4,096 tokens. A single token corresponds to three or four characters in languages like English, Spanish, or German, and one token per character in languages like Japanese, Chinese, or Korean. In a single session, the sum of all tokens in the instructions, all prompts, and all outputs count toward the context window size.
If your session processes a large amount of tokens that exceed the context window, the framework throws the error LanguageModelSession.GenerationError.exceededContextWindowSize(_:). When you encounter the error, start a new session and try shortening your prompts. If you need to process a large amount of data that won’t fit in a single context window limit, break your data into smaller chunks, process each chunk in a separate session, and then combine the results.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.
Tune generation options and optimize performance
To get the best results for your prompt, experiment with different generation options. GenerationOptions affects the runtime parameters of the model, and you can customize them for every request you make.
// Customize the temperature to increase creativity.

```swift
let options = GenerationOptions(temperature: 2.0)


let session = LanguageModelSession()


let prompt = "Write me a story about coffee."
let response = try await session.respond(
    to: prompt,
    options: options
```
)
When you test apps that use the framework, use Xcode Instruments to understand more about the requests you make, like the time it takes to perform a request. When you make a request, you can access the Transcript entries that describe the actions the model takes during your LanguageModelSession.

## See Also

Essentials

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
struct UseCase
```
A type that represents the use case for prompting.



# Article

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

## Overview

Generative AI models have powerful creativity, but with this creativity comes the risk of unintended or unexpected results. For any generative AI feature, safety needs to be an essential part of your design.
The Foundation Models framework has two base layers of safety, where the framework uses:
- An on-device language model that has training to handle sensitive topics with care.
- Guardrails that aim to block harmful or sensitive content, such as self-harm, violence, and adult materials, from both model input and output.
Because safety risks are often contextual, some harms might bypass both built-in framework safety layers. It’s vital to design additional safety layers specific to your app. When developing your feature, decide what’s acceptable or might be harmful in your generative AI feature, based on your app’s use case, cultural context, and audience.
For more information on designing generative AI experiences responsibly, see Human Interface Guidelines > Foundations > Generative AI.
Handle guardrail errors
When you send a prompt to the model, SystemLanguageModel.Guardrails check the input prompt and the model’s output. If either fails the guardrail’s safety check, the model session throws a LanguageModelSession.GenerationError.guardrailViolation(_:) error:

```swift
do {
    let session = LanguageModelSession()
    let topic = // A potentially harmful topic.
    let prompt = "Write a respectful and funny story about \(topic)."
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.guardrailViolation {
    // Handle the safety error.
}
```
If you encounter a guardrail violation error for any built-in prompt in your app, experiment with re-phrasing the prompt to determine which phrases are activating the guardrails, and avoid those phrases. If the error is thrown in response to a prompt created by someone using your app, give people a clear message that explains the issue. For example, you might say “Sorry, this feature isn’t designed to handle that kind of input” and offer people the opportunity to try a different prompt.
Handle model refusals
The on-device language model may not be suitable for handling all requests and may refuse requests for a topic. When you generate a string response, and the model refuses a request, it generates a message that begins with a refusal like “Sorry, I can’t help with”.
Design your app experience with refusal messages in mind and present the message to the person using your app. You might not be able to programmatically determine whether a string response is a normal response or a refusal, so design the experience to anticipate both. If it’s critical to determine whether the response is a refusal message, initialize a new LanguageModelSession and prompt the model to classify whether the string is a refusal.
When you use guided generation to generate Swift structures or types, there’s no placeholder for a refusal message. Instead, the model throws a LanguageModelSession.GenerationError.refusal(_:_:) error. When you catch the error, you can ask the model to generate a string refusal message:

```swift
do {
    let session = LanguageModelSession()
    let topic = ""  // A sensitive topic.
    let response = try session.respond(
        to: "List five key points about: \(topic)",
        generating: [String].self
    )
} catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
    // Generate an explanation for the refusal.
    if let message = try? await refusal.explanation {
        // Display the refusal message.
    }
}
```
Display the explanation in your app to tell people why a request failed, and offer people the opportunity to try a different prompt. Retrieving an explanation message is asynchronous and takes time for the model to generate.
If you encounter a refusal message, or refusal error, for any built-in prompts in your app, experiment with re-phrasing your prompt to avoid any sensitive topics that might cause the refusal.
For more information about guided generation, see Generating Swift data structures with guided generation.
Build boundaries on input and output
Safety risks increase when a prompt includes direct input from a person using your app, or from an unverified external source, like a webpage. An untrusted source makes it difficult to anticipate what the input contains. Whether accidentally or on purpose, someone could input sensitive content that causes the model to respond poorly.
Tip
The more you can define the intended usage and outcomes for your feature, the more you can ensure generation works great for your app’s specific use cases. Add boundaries to limit out-of-scope usage and minimize low generation quality from out-of-scope uses.
Whenever possible, avoid open input in prompts and place boundaries for controlling what the input can be. This approach helps when you want generative content to stay within the bounds of a particular topic or task. For the highest level of safety on input, give people a fixed set of prompts to choose from. This gives you the highest certainty that sensitive content won’t make its way into your app:

```swift
enum TopicOptions {
    case family
    case nature
    case work 
}
let topicChoice = TopicOptions.nature
let prompt = """
    Generate a wholesome and empathetic journal prompt that helps \
    this person reflect on \(topicChoice)
    """
```
If your app allows people to freely input a prompt, placing boundaries on the output can also offer stronger safety guarantees. Using guided generation, create an enumeration to restrict the model’s output to a set of predefined options designed to be safe no matter what:

```swift
@Generable
enum Breakfast {
    case waffles
    case pancakes
    case bagels
    case eggs 
}
let session = LanguageModelSession()
let userInput = "I want something sweet."
let prompt = "Pick the ideal breakfast for request: \(userInput)"
let response = try await session.respond(to: prompt, generating: Breakfast.self)
```
Instruct the model for added safety
Consider adding detailed session Instructions that tell the model how to handle sensitive content. The language model prioritizes following its instructions over any prompt, so instructions are an effective tool for improving safety and overall generation quality. Use uppercase words to emphasize the importance of certain phrases for the model:

```swift
do {
    let instructions = """
        ALWAYS respond in a respectful way. \
        If someone asks you to generate content that might be sensitive, \
        you MUST decline with 'Sorry, I can't do that.'
        """
    let session = LanguageModelSession(instructions: instructions)
    let prompt = // Open input from a person using the app.
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.guardrailViolation {
    // Handle the safety error.
}
```
Note
A session obeys instructions over a prompt, so don’t include input from people or any unverified input in the instructions. Using unverified input in instructions makes your app vulnerable to prompt injection attacks, so write instructions with content you trust.
If you want to include open-input from people, instructions for safety are recommended. For an additional layer of safety, use a format string in normal prompts that wraps people’s input in your own content that specifies how the model should respond:

```swift
let userInput = // The input a person enters in the app.
let prompt = """
    Generate a wholesome and empathetic journal prompt that helps \
    this person reflect on their day. They said: \(userInput)
    """
```
Add a deny list of blocked terms
If you allow prompt input from people or outside sources, consider adding your own deny list of terms. A deny list is anything you don’t want people to be able to input to your app, including unsafe terms, names of people or products, or anything that’s not relevant to the feature you provide. Implement a deny list similarly to guardrails by creating a function that checks the input and the model output:

```swift
let session = LanguageModelSession()
let userInput = // The input a person enters in the app.
let prompt = "Generate a wholesome story about: \(userInput)"


```
// A function you create that evaluates whether the input 
// contains anything in your deny list.

```swift
if verifyText(prompt) { 
    let response = try await session.respond(to: prompt)
    
    // Compare the output to evaluate whether it contains anything in your deny list.
    if verifyText(response.content) { 
        return response 
    } else {
        // Handle the unsafe output.
    }
} else {
    // Handle the unsafe input.
}
```
A deny list can be a simple list of strings in your code that you distribute with your app. Alternatively, you can host a deny list on a server so your app can download the latest deny list when it’s connected to the network. Hosting your deny list allows you to update your list when you need to and avoids requiring a full app update if a safety issue arise.
Use permissive guardrail mode for sensitive content
The default SystemLanguageModel guardrails may throw a LanguageModelSession.GenerationError.guardrailViolation(_:) error for sensitive source material. For example, it may be appropriate for your app to work with certain inputs from people and unverified sources that might contain sensitive content:
- When you want the model to tag the topic of conversations in a chat app when some messages contain profanity.
- When you want to use the model to explain notes in your study app that discuss sensitive topics.
To allow the model to reason about sensitive source material, use permissiveContentTransformations when you initialize SystemLanguageModel:

```swift
let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
```
This mode only works for generating a string value. When you use guided generation, the framework runs the default guardrails against model input and output as usual, and generates LanguageModelSession.GenerationError.guardrailViolation(_:) and LanguageModelSession.GenerationError.refusal(_:_:)errors as usual.
Before you use permissive content mode, consider what’s appropriate for your audience. The session skips the guardrail checks in this mode, so it never throws a LanguageModelSession.GenerationError.guardrailViolation(_:) error when generating string responses.
However, even with the SystemLanguageModel guardrails off, the on-device system language model still has a layer of safety. For some content, the model may still produce a refusal message that’s similar to, “Sorry, I can’t help with.”
Create a risk assessment
Conduct a risk assessment to proactively address what might go wrong. Risk assessment is an exercise that helps you brainstorm potential safety risks in your app and map each risk to an actionable mitigation. You can write a risk assessment in any format that includes these essential elements:
- List each AI feature in your app.
- For each feature, list possible safety risks that could occur, even if they seem unlikely.
- For each safety risk, score how serious the harm would be if that thing occurred, from mild to critical.
- For each safety risk, assign a strategy for how you’ll mitigate the risk in your app.
For example, an app might include one feature with the fixed-choice input pattern for generation and one feature with the open-input pattern for generation, which is higher safety risk:
Feature
Harm
Severity
Mitigation
Player can input any text to chat with nonplayer characters in the coffee shop.
A character might respond in an insensitive or harmful way.
Critical
Instructions and prompting to steer characters responses to be safe; safety testing.
Image generation of an imaginary dream customer, like a fairy or a frog.
Generated image could look weird or scary.
Mild
Include in the prompt examples of images to generate that are cute and not scary; safety testing.
Player can make a coffee from a fixed menu of options.
None identified.


Generate a review of the coffee the player made, based on the customer’s order.
Review could be insulting.
Moderate
Instructions and prompting to encourage posting a polite review; safety testing.
Besides obvious harms, like a poor-quality model output, think about how your generative AI feature might affect people, including real-world scenarios where someone might act based on information generated by your app.
Write and maintain safety tests
Although most people will interact with your app in respectful ways, it’s important to anticipate possible failure modes where certain input or contexts could cause the model to generate something harmful. Especially if your app takes input from people, test your experience’s safety on input like:
- Input that is nonsensical, snippets of code, or random characters.
- Input that includes sensitive content.
- Input that includes controversial topics.
- Vague or unclear input that could be misinterpreted.
Create a list of potentially harmful prompt inputs that you can run as part of your app’s tests. Include every prompt in your app — even safe ones — as part of your app testing. For each prompt test, log the timestamp, full input prompt, the model’s response, and whether it activates any built-in safety or mitigations you’ve included in your app. When starting out, manually read the model’s response on all tests to ensure it meets your design and safety goals. To scale your tests, consider using a frontier LLM to auto-grade the safety of each prompt. Building a test pipeline for prompts and safety is a worthwhile investment for tracking changes in how your app responds over time.
Someone might purposefully attempt to break your feature or produce bad output — especially someone who won’t be harmed by their actions. But, keep in mind that it’s very important to identify cases where someone might accidentally be harmed during normal app use.
Tip
Prioritize protecting people using your app with good intentions. Accidental safety failures often only occur in specific contexts, which make them hard to identify during testing. Test for a longer series of interactions, and test for inputs that could become sensitive only when combined with other aspects of your app.
Don’t engage in any testing that could cause you or others harm. Apple’s built-in responsible AI and safety measures, like safety guardrails, are built by experts with extensive training and support. These built-in measures aim to block egregious harms, allowing you to focus on the borderline harmful cases that need your judgement. Before conducting any safety testing, ensure that you’re in a safe location and that you have the health and well-being support you need.
Report safety concerns
Somewhere in your app, it’s important to include a way that people can report potentially harmful content. Continuously monitor the feedback you receive, and be responsive to quickly handling any safety issues that arise. If someone reports a safety concern that you believe isn’t being properly handled by Apple’s built-in guardrails, report it to Apple with Feedback Assistant.
The Foundation Models framework offers utilities for feedback. Use LanguageModelFeedback to retrieve language model session transcripts from people using your app. After collecting feedback, you can serialize it into a JSON file and include it in the report you send with Feedback Assistant.
Monitor safety for model or guardrail updates
Apple releases updates to the system model as part of regular OS updates. If you participate in the developer beta program you can test your app with new model version ahead of people using your app. When the model updates, it’s important to re-run your full prompt tests in addition to your adversarial safety tests because the model’s response may change. Your risk assessment can help you track any change to safety risks in your app.
Apple may update the built-in guardrails at any time outside of the regular OS update cycle. This is done to rapidly respond, for example, to reported safety concerns that require a fast response. Include all of the prompts you use in your app in your test suite, and run tests regularly to identify when prompts start activating the guardrails.

## See Also

Essentials

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
struct UseCase
```
A type that represents the use case for prompting.


# Article

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

## Overview

The on-device system language model is multilingual, which means the same model understands and generates text in any language that Apple Intelligence supports. The model supports using different languages for prompts, instructions, and the output that the model produces.
When you enhance your app with multilingual support, generate content in the language people prefer to use when they interact with your app by:
- Prompting the model with the language you prefer.
- Including the target language for your app in the instructions you provide the model.
- Determining the language or languages a person wants to use when they interact with your app.
- Gracefully handling languages that Apple Intelligence doesn’t support.
For more information about the languages and locales that Apple Intelligence supports, see the “Supported languages” section in How to get Apple Intelligence.
Prompt the model in the language you prefer
Write your app’s built-in prompts in the language with which you normally write code, if Apple Intelligence supports that language. Translate your prompts into a supported language if your preferred language isn’t supported. In the code below, all inputs need to be in supported language for the model to understand, including all Generable types and descriptions:

```swift
@Generable(description: "Basic profile information about a cat")
struct CatProfile {
    var name: String


    @Guide(description: "The age of the cat", .range(0...20))
    var age: Int


    @Guide(description: "One sentence about this cat's personality")
    var profile: String
}


#Playground {
    let response = try await LanguageModelSession().respond(
        to: "Generate a rescue cat",
        generating: CatProfile.self
    )
}
```
Because the framework treats Generable types as model inputs, the names of properties like age or profile are just as important as the @Guide descriptions for helping the model understand your request.
Check a person’s language settings for your app
People can use the Settings app on their device to configure the language they prefer to use on a per-app basis, which might differ from their default language. If your app supports a language that Apple Intelligence doesn’t, you need to verify that the current language setting of your app is supported before you call the model. Keep in mind that language support improves over time in newer model and OS versions. Thus, someone using your app with an older OS may not have the latest language support.
Before you call the model, run supportsLocale(_:) to verify the support for a locale. By default, the method uses current, which takes into account a person’s current language and app-specific settings. This method returns true if the model supports this locale, or if this locale is considered similar enough to a supported locale, such as en-AU and en-NZ:

```swift
if SystemLanguageModel.default.supportsLocale() {
    // Language is supported.
}
```
For advanced use cases where you need full language support details, use supportedLanguages to retrieve a list of languages supported by the on-device model.
Handle an unsupported language or locale errors
When you call respond(to:options:) on a LanguageModelSession, the Foundation Models framework checks the language or languages of the input prompt text, and whether your prompt asks the model to respond in any specific language or languages. If the model detects a language it doesn’t support, the session throws LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(_:). Handle the error by communicating to the person using your app that a language in their request is unsupported.
If your app supports languages or locales that Apple Intelligence doesn’t, help people that use your app by:
- Explaining that their language isn’t supported by Apple Intelligence in your app.
- Disabling your Foundation Models framework feature.
- Providing an alternative app experience, if possible.
Important
Guardrails for model input and output safety are only for supported languages and locales. If a prompt contains sensitive content in an unsupported language, which typically is a short phrase mixed-in with text in a supported language, it might not throw a LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(_:) error. If unsupported-language detection fails, the guardrails may also fail to flag that short, unsupported content. For more on guardrails, see Improving the safety of generative model output.
Use Instructions to set the locale and language
For locales other than United States English, you can improve response quality by telling the model which locale to use by detailing a set of Instructions. Start with the exact phrase in English. This special phrase comes from the model’s training, and reduces the possibility of hallucinations in multilingual situations:

```swift
func localeInstructions(for locale: Locale = Locale.current) -> String {
    if Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
        // Skip the locale phrase for U.S. English.
        return "" 
    } else {
        // Specify the person's locale with the exact phrase format.
        return "The person's locale is \(locale.identifier)."
    }
}
```
After you set the locale in Instructions, you may need to explicitly set the model output language. By default, the model responds in the language or languages of its inputs. If your app supports multiple languages, prompts that you write and inputs from people using your app might be in different languages. For example, if you write your built-in prompts in Spanish, but someone using your app writes inputs in Dutch, the model may respond in either or both languages.
Use Instructions to explicity tell the model which language or languages with witch it needs to respond. You can phrase this request in different ways, for example: “You MUST respond in Italian” or “You MUST respond in Italian and be mindful of Italian spelling, vocabulary, entities, and other cultural contexts of Italy.” These instructions can be in the language you prefer.

```swift
let session = LanguageModelSession(
    instructions: "You MUST respond in U.S. English."
```
)

```swift
let prompt = // A prompt that contains Spanish and Italian.
let response = try await session.respond(to: prompt)
```
Finally, thoroughly test your instructions to ensure the model is responding in the way you expect. If the model isn’t following your instructions, try capitalized words like “MUST” or “ALWAYS” to strengthen your instructions.

## See Also

Essentials

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
struct UseCase
```
A type that represents the use case for prompting.


# Sample Code

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.
Download
> iOS 26.0+
> iPadOS 26.0+
> macOS 26.0+
> visionOS 26.0+
> Xcode 26.0+

## Overview

This sample project shows how to integrate generative AI capabilities into an app using the Foundation Models framework. The sample app showcases intelligent trip planning features that help people discover landmarks and generate personalized itineraries.
The app creates an interactive experience where people can:
- Browse curated landmarks with rich visual content
- Generate trip itineraries tailored to a chosen landmark
- Discover points of interest using a custom tool
- Experience real-time content generation with streaming responses
Note
This sample code project is associated with WWDC25 session 259: Code-along: Add Intelligence to your App using the Foundation Models framework.
Configure the sample code project
To run this sample, you’ll need to:
	0.	Set the developer team in Xcode for the app target so it automatically manages the provisioning profile. For more information, see Set the bundle ID and Assign the project to a team.
	0.	In the Developer portal, enable the WeatherKit app service for your bundle ID so the app can access location-based weather information.
Check model availability
Before using the on-device model in the app, check that the model is available by creating an instance of SystemLanguageModel with the default property:

```swift
let landmark: Landmark
```
private let model = SystemLanguageModel.default



```swift
var body: some View {
    switch model.availability {
    case .available:
        LandmarkTripView(landmark: landmark)
    case .unavailable(.appleIntelligenceNotEnabled):
        MessageView(
            landmark: self.landmark,
            message: """
                     Trip Planner is unavailable because \
                     Apple Intelligence hasn't been turned on.
                     """
        )
    case .unavailable(.modelNotReady):
        MessageView(
            landmark: self.landmark,
            message: "Trip Planner isn't ready yet. Try again later."
        )
    }
}
```
The app handles two unavailability scenarios: Apple Intelligence isn’t enabled or the model isn’t ready for usage. If Apple Intelligence is off, the app tells the person they need to turn it on and if the model isn’t ready, it tells the person the Trip Planner isn’t ready and to try the app again later.
Note
To use the on-device language model, people need to turn on Apple Intelligence on their device. For a list of supported devices, see Apple Intelligence.
Define structured data for generation
The app starts by defining data structures with specific constraints to control what the model generates. The Itinerary type uses the Generable macro to create structured content that includes travel plans with activities, hotels, and restaurants.
The @Generable macro automatically converts Swift types into schemas that the model uses for constrained sampling, so you can specify guides to control the values you associate with it. For example, the app uses Guide(description:) to make sure the model creates an exciting name for the trip. It also uses anyOf(_:) and count(_:) to choose any destination from our ModelData and show exactly 3 DayPlan objects per destination, respectively.

```swift
@Generable
struct Itinerary: Equatable {
    @Guide(description: "An exciting name for the trip.")
    let title: String
    @Guide(.anyOf(ModelData.landmarkNames))
    let destinationName: String
    let description: String
    @Guide(description: "An explanation of how the itinerary meets the person's special requests.")
    let rationale: String


    @Guide(description: "A list of day-by-day plans.")
    @Guide(.count(3))
    let days: [DayPlan]
}


@Generable
struct DayPlan: Equatable {
    @Guide(description: "A unique and exciting title for this day plan.")
    let title: String
    let subtitle: String
    let destination: String


    @Guide(.count(3))
    let activities: [Activity]
}


@Generable
struct Activity: Equatable {
    let type: Kind
    let title: String
    let description: String
}


@Generable
enum Kind {
    case sightseeing
    case foodAndDining
    case shopping
    case hotelAndLodging
}
```
The @Generable macro automatically creates two versions of each type: the complete structure and a PartiallyGenerated version which is a mirror of the outer structure except every property is optional. The app uses this PartiallyGenerated version when streaming and displaying the itinerary generation.
Configure the model session
After checking that the model is available, the app configures a LanguageModelSession object with custom tools and detailed instructions in ItineraryPlanner. Given a location, the initializer creates the session with structured guidance for generating personalized trip recommendations.

```swift
init(landmark: Landmark) {
    self.landmark = landmark
    Logging.general.log("The landmark is... \(landmark.name)")
    let pointOfInterestTool = FindPointsOfInterestTool(landmark: landmark)
    self.session = LanguageModelSession(
        tools: [pointOfInterestTool],
        instructions: Instructions {
            "Your job is to create an itinerary for the person."
            
            "Each day needs an activity, hotel and restaurant."
            
            """
            Always use the findPointsOfInterest tool to find businesses \
            and activities in \(landmark.name), especially hotels \
            and restaurants.
            
            The point of interest categories may include:
            """
            FindPointsOfInterestTool.categories
            
            """
            Here is a description of \(landmark.name) for your reference \
            when considering what activities to generate:
            """
            landmark.description
        }
    )
    self.pointOfInterestTool = pointOfInterestTool
}
```
In a generated itinerary, the model instructions ensure that each day contains an activity, hotel, and restaurant. To get the location-specific businesses and activities, the sample uses a custom tool, called FindPointsOfInterestTool, with the chosen landmark. The instructions also call the landmark description property as added context when generating the activities.
Create a custom tool
You can use custom tools to extend the functionality of a model. Tool-calling allows the model to interact with external code you create to fetch up-to-date information, ground responses in sources of truth that you provide, and perform side effects.
The model in this app uses the FindPointsOfInterestTool tool to enable dynamic discovery of specific businesses and activities for the chosen landmark. The tool uses the @Generable macro to make its categories and arguments available to the model.

```swift
@Observable
final class FindPointsOfInterestTool: Tool {
    let name = "findPointsOfInterest"
    let description = "Finds points of interest for a landmark."
    
    let landmark: Landmark
    
    @MainActor var lookupHistory: [Lookup] = []
    
    init(landmark: Landmark) {
        self.landmark = landmark
    }


@Generable
enum Category: String, CaseIterable {
    case campground
    case hotel
    case cafe
    case museum
    case marina
    case restaurant
    case nationalMonument
}


@Generable
struct Arguments {
    @Guide(description: "This is the type of destination to look up for.")
    let pointOfInterest: Category


    @Guide(description: "The natural language query of what to search for.")
    let naturalLanguageQuery: String
}
```
When you prompt the model with a question or make a request, the model decides whether it can provide an answer or if it needs the help of a tool. The app explicitly instructs the model to always use the findPointsOfInterestTool in the ItineraryPlanner instructions. This allows the model to automatically call the tool to find relevant hotels, restaurants, and activities for the destinations.
Stream and display partial responses in real time
The app shows real-time content generation by streaming partial responses from the model. The ItineraryPlanner uses streamResponse(generating:includeSchemaInPrompt:options:prompt:) to generate Itinerary.PartiallyGenerated objects so itinerary items are shown incrementally to the person.
You can opt for specific GenerationOptions to adjust the way the model generates these responses. For generating the itinerary, the app opts for a greedy sampling mode so the model always results in the same output for a given input. This ensures the prompt generates consistent recommendations for an itinerary specific to the given landmark.
private(set) var itinerary: Itinerary.PartiallyGenerated?



```swift
func suggestItinerary(dayCount: Int) async throws {
    let stream = session.streamResponse(
        generating: Itinerary.self,
        includeSchemaInPrompt: false,
        options: GenerationOptions(sampling: .greedy)
    ) {
        "Generate a \(dayCount)-day itinerary to \(landmark.name)."


        "Give it a fun title and description."


        "Here is an example, but don't copy it:"
        Itinerary.exampleTripToJapan
    }


    for try await partialResponse in stream {
        itinerary = partialResponse.content
    }
}
```
The app presents the responses in a SwiftUI view. The ItineraryPlanningView displays real-time visual feedback as the model searches for points of interest, showing people what’s happening when generating content:
ForEach(planner.pointOfInterestTool.lookupHistory) { element in

```swift
    HStack {
        Image(systemName: "location.magnifyingglass")
        Text("Searching **\(element.history.pointOfInterest.rawValue)** in \(landmark.name)...")
    }
    .transition(.blurReplace)
}
```
The app displays messages like “Searching hotel in Yosemite…” and “Searching restaurant in Yosemite…” to let people know which point of interest category the model provided as input to the tool when actively searching for nearby points of interest. In the background, however, the tool executes and provides updates to the view. The view shows a blurred overlay while generating each day plan, then reveals the full itinerary after the search completes.
Tag content dynamically
The app uses content tagging on the provided landmarks to help people quickly understand the characteristics of each destination. A content tagging model produces a list of categorizing tags based on the input text you provide. When you prompt the content tagging model, it produces a tag that uses one to a few lowercase words. The LandmarkDescriptionView prompts the content tagging model to automatically generate relevant hashtags for landmark descriptions, like #nature, #hiking, or #scenic, based on each landmark’s description. For more information on initializing content tagging, see Categorizing and organizing data with content tags.

```swift
let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)


.task {
    if !contentTaggingModel.isAvailable { return }
    do {
        let session = LanguageModelSession(model: contentTaggingModel)
        let stream = session.streamResponse(
            to: landmark.description,
            generating: TaggingResponse.self,
            options: GenerationOptions(sampling: .greedy)
        )
        for try await newTags in stream {
            generatedTags = newTags.content
        }
    } catch {
        Logging.general.error("\(error.localizedDescription)")
    }
}
```
Integrate with other framework features
You can combine these generative model features with other Apple frameworks. For example, the LocationLookup class uses MapKit to search for addresses for our points of interest, showing how to combine model-generated content with weather information and location data for complete travel planning.

```swift
@Observable @MainActor
final class LocationLookup {
    private(set) var item: MKMapItem?
    private(set) var temperatureString: String?


    func performLookup(location: String) {
        Task {
            let item = await self.mapItem(atLocation: location)
            if let location = item?.location {
                self.temperatureString = await self.weather(atLocation: location)
            }
        }
    }
    
    private func mapItem(atLocation location: String) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = location
        
        let search = MKLocalSearch(request: request)
        do {
            return try await search.start().mapItems.first
        } catch {
            Logging.general.error("Failed to look up location: \(location). Error: \(error)")
        }
        return nil
    }
}
```
The model generates location names as text, and the LocationLookup class converts them into real, mappable locations using the natural language search capabilities in MapKit.

## See Also

Essentials

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
struct UseCase
```
A type that represents the use case for prompting.


# Class

SystemLanguageModel
An on-device large language model capable of text generation tasks.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final class SystemLanguageModel

## Mentioned in


Improving the safety of generative model output

Generating content and performing tasks with Foundation Models

Loading and using a custom adapter with Foundation Models

## Overview

The SystemLanguageModel refers to the on-device text foundation model that powers Apple Intelligence. Use default to access the base version of the model and perform general-purpose text generation tasks. To access a specialized version of the model, initialize the model with SystemLanguageModel.UseCase to perform tasks like contentTagging.
Verify the model availability before you use the model. Model availability depends on device factors like:
- The device must support Apple Intelligence.
- Apple Intelligence must be turned on in Settings.
Use SystemLanguageModel.Availability to change what your app shows to people based on the availability condition:

```swift
struct GenerativeView: View {
    // Create a reference to the system language model.
    private var model = SystemLanguageModel.default


    var body: some View {
        switch model.availability {
        case .available:
            // Show your intelligence UI.
        case .unavailable(.deviceNotEligible):
            // Show an alternative UI.
        case .unavailable(.appleIntelligenceNotEnabled):
            // Ask the person to turn on Apple Intelligence.
        case .unavailable(.modelNotReady):
            // The model isn't ready because it's downloading or because
            // of other system reasons.
        case .unavailable(let other):
            // The model is unavailable for an unknown reason.
        }
    }
}
```

## Topics

Loading the model with a use case
convenience init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)
Creates a system language model for a specific use case.

```swift
struct UseCase
```
A type that represents the use case for prompting.

```swift
struct Guardrails
```
Guardrails flag sensitive content from model input and output.
Loading the model with an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.
Checking model availability

```swift
var isAvailable: Bool
```
A convenience getter to check if the system is entirely ready.

```swift
var availability: SystemLanguageModel.Availability
```
The availability of the language model.

```swift
enum Availability
```
The availability status for a specific system language model.
Retrieving the supported languages

```swift
var supportedLanguages: Set<Locale.Language>
```
Languages that the model supports.
Determining whether the model supports a locale

```swift
func supportsLocale(Locale) -> Bool
```
Returns a Boolean indicating whether the given locale is supported by the model.
Getting the default model
static let `default`: SystemLanguageModel
The base version of the model.

## Relationships


## Conforms To

- Copyable
- Observable
- Sendable
- SendableMetatype

## See Also

Essentials

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
struct UseCase
```
A type that represents the use case for prompting.


## Initializer


```swift
init(useCase:guardrails:)
```
Creates a system language model for a specific use case.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
convenience init(
    useCase: SystemLanguageModel.UseCase = .general,
    guardrails: SystemLanguageModel.Guardrails = Guardrails.default
```
)

## See Also

Loading the model with a use case

```swift
struct UseCase
```
A type that represents the use case for prompting.

```swift
struct Guardrails
```
Guardrails flag sensitive content from model input and output.


# Structure

SystemLanguageModel.UseCase
A type that represents the use case for prompting.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct UseCase
```

## Topics

Getting the general use case

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.
static let general: SystemLanguageModel.UseCase
A use case for general prompting.
Getting the content tagging use case

Categorizing and organizing data with content tags
Identify topics, actions, objects, and emotions in input text with a content tagging model.
static let contentTagging: SystemLanguageModel.UseCase
A use case for content tagging.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Essentials

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.


# Article

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

## Overview

The Foundation Models framework lets you tap into the on-device large models at the core of Apple Intelligence. You can enhance your app by using generative models to create content or perform tasks. The framework supports language understanding and generation based on model capabilities.
For design guidance, see Human Interface Guidelines > Technologies > Generative AI.
Understand model capabilities
When considering features for your app, it helps to know what the on-device language model can do. The on-device model supports text generation and understanding that you can use to:
Capability
Prompt example
Summarize
“Summarize this article.”
Extract entities
“List the people and places mentioned in this text.”
Understand text
“What happens to the dog in this story?”
Refine or edit text
“Change this story to be in second person.”
Classify or judge text
“Is this text relevant to the topic ‘Swift’?”
Compose creative writing
“Generate a short bedtime story about a fox.”
Generate tags from text
“Provide two tags that describe the main topics of this text.”
Generate game dialog
“Respond in the voice of a friendly inn keeper.”
The on-device language model may not be suitable for handling all requests, like:
Capabilities to avoid
Prompt example
Do basic math
“How many b’s are there in bagel?”
Create code
“Generate a Swift navigation list.”
Perform logical reasoning
“If I’m at Apple Park facing Canada, what direction is Texas?”
The model can complete complex generative tasks when you use guided generation or tool calling. For more on handling complex tasks, or tasks that require extensive world-knowledge, see Generating Swift data structures with guided generation and Expanding generation with tool calling.
Check for availability
Before you use the on-device model in your app, check that the model is available by creating an instance of SystemLanguageModel with the default property.
Model availability depends on device factors like:
- The device must support Apple Intelligence.
- The device must have Apple Intelligence turned on in Settings.
Note
It can take some time for the model to download and become available when a person turns on Apple Intelligence.
Always verify model availability first, and plan for a fallback experience in case the model is unavailable.

```swift
struct GenerativeView: View {
    // Create a reference to the system language model.
    private var model = SystemLanguageModel.default


    var body: some View {
        switch model.availability {
        case .available:
            // Show your intelligence UI.
        case .unavailable(.deviceNotEligible):
            // Show an alternative UI.
        case .unavailable(.appleIntelligenceNotEnabled):
            // Ask the person to turn on Apple Intelligence.
        case .unavailable(.modelNotReady):
            // The model isn't ready because it's downloading or because of other system reasons.
        case .unavailable(let other):
            // The model is unavailable for an unknown reason.
        }
    }
}
```
Create a session
After confirming that the model is available, create a LanguageModelSession object to call the model. For a single-turn interaction, create a new session each time you call the model:
// Create a session with the system model.

```swift
let session = LanguageModelSession()
```
For a multiturn interaction — where the model retains some knowledge of what it produced — reuse the same session each time you call the model.
Provide a prompt to the model
A Prompt is an input that the model responds to. Prompt engineering is the art of designing high-quality prompts so that the model generates a best possible response for the request you make. A prompt can be as short as “hello”, or as long as multiple paragraphs. The process of designing a prompt involves a lot of exploration to discover the best prompt, and involves optimizing prompt length and writing style.
When thinking about the prompt you want to use in your app, consider using conversational language in the form of a question or command. For example, “What’s a good month to visit Paris?” or “Generate a food truck menu.”
Write prompts that focus on a single and specific task, like “Write a profile for the dog breed Siberian Husky”. When a prompt is long and complicated, the model takes longer to respond, and may respond in unpredictable ways. If you have a complex generation task in mind, break the task down into a series of specific prompts.
You can refine your prompt by telling the model exactly how much content it should generate. A prompt like, “Write a profile for the dog breed Siberian Husky” often takes a long time to process as the model generates a full multi-paragraph essay. If you specify “using three sentences”, it speeds up processing and generates a concise summary. Use phrases like “in a single sentence” or “in a few words” to shorten the generation time and produce shorter text.
// Generate a longer response for a specific command.

```swift
let simple = "Write me a story about pears."


```
// Quickly generate a concise response.

```swift
let quick = "Write the profile for the dog breed Siberian Husky using three sentences."
```
Provide instructions to the model
Instructions help steer the model in a way that fits the use case of your app. The model obeys prompts at a lower priority than the instructions you provide. When you provide instructions to the model, consider specifying details like:
- What the model’s role is; for example, “You are a mentor,” or “You are a movie critic”.
- What the model should do, like “Help the person extract calendar events,” or “Help the person by recommending search suggestions”.
- What the style preferences are, like “Respond as briefly as possible”.
- What the possible safety measures are, like “Respond with ‘I can’t help with that’ if you’re asked to do something dangerous”.
Use content you trust in instructions because the model follows them more closely than the prompt itself. When you initialize a session with instructions, it affects all prompts the model responds to in that session. Instructions can also include example responses to help steer the model. When you add examples to your prompt, you provide the model with a template that shows the model what a good response looks like.
Generate a response
To call the model with a prompt, call respond(to:options:) on your session. The response call is asynchronous because it may take a few seconds for the on-device foundation model to generate the response.

```swift
let instructions = """
    Suggest five related topics. Keep them concise (three to seven words) and make sure they \
    build naturally from the person's topic.
    """


let session = LanguageModelSession(instructions: instructions)


let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)
```
Note
A session can only handle a single request at a time, and causes a runtime error if you call it again before the previous request finishes. Check isResponding to verify the session is done processing the previous request before sending a new one.
Instead of working with raw string output from the model, the framework offers guided generation to generate a custom Swift data structure you define. For more information about guided generation, see Generating Swift data structures with guided generation.
When you make a request to the model, you can provide custom tools to help the model complete the request. If the model determines that a Tool can assist with the request, the framework calls your Tool to perform additional actions like retrieving content from your local database. For more information about tool calling, see Expanding generation with tool calling
Consider context size limits per session
The context window size is a limit on how much data the model can process for a session instance. A token is a chunk of text the model processes, and the system model supports up to 4,096 tokens. A single token corresponds to three or four characters in languages like English, Spanish, or German, and one token per character in languages like Japanese, Chinese, or Korean. In a single session, the sum of all tokens in the instructions, all prompts, and all outputs count toward the context window size.
If your session processes a large amount of tokens that exceed the context window, the framework throws the error LanguageModelSession.GenerationError.exceededContextWindowSize(_:). When you encounter the error, start a new session and try shortening your prompts. If you need to process a large amount of data that won’t fit in a single context window limit, break your data into smaller chunks, process each chunk in a separate session, and then combine the results.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.
Tune generation options and optimize performance
To get the best results for your prompt, experiment with different generation options. GenerationOptions affects the runtime parameters of the model, and you can customize them for every request you make.
// Customize the temperature to increase creativity.

```swift
let options = GenerationOptions(temperature: 2.0)


let session = LanguageModelSession()


let prompt = "Write me a story about coffee."
let response = try await session.respond(
    to: prompt,
    options: options
```
)
When you test apps that use the framework, use Xcode Instruments to understand more about the requests you make, like the time it takes to perform a request. When you make a request, you can access the Transcript entries that describe the actions the model takes during your LanguageModelSession.

## See Also

Essentials

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
struct UseCase
```
A type that represents the use case for prompting.



## Type Property

general
A use case for general prompting.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let general: SystemLanguageModel.UseCase
```

## Mentioned in


Categorizing and organizing data with content tags

## Discussion

This is the default use case for the base version of the model, so if you use SystemLanguageModel/default, you don’t need to specify a use case.

## See Also

Getting the general use case

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.


# Article

Categorizing and organizing data with content tags
Identify topics, actions, objects, and emotions in input text with a content tagging model.

## Overview

The Foundation Models framework provides an adapted on-device system language model that specializes in content tagging. A content tagging model produces a list of categorizing tags based on the input text you provide. When you prompt the content tagging model, it produces a tag that uses one to a few lowercase words. The model finds the similarity between the terms in your prompt so tags are semantically consistent. For example, the model produces the topic tag “greet” when it encounters words such as “hi,” “hello,” and “yo”. Use the content tagging model to:
- Gather statistics about popular topics and opinions in a social app.
- Customize your app’s experience by matching tags to a person’s interests.
- Help people organize their content for tasks such as email autolabeling using the tags your app detects.
- Identify trends by aggregating tags across your content.
If you’re tagging content that’s not an action, object, emotion, or topic, use general instead. Use the general model to generate content like hashtags for social media posts. If you adopt the tool calling API, and want to generate tags, use general and pass the Tool output to the content tagging model. For more information about tool-calling, see Expanding generation with tool calling.
Provide instructions to the model
The content tagging model isn’t a typical language model that responds to a query from a person: instead, it evaluates and groups the input you provide. For example, if you ask the model questions, it produces tags about asking questions. Before you prompt the model, consider the instructions you want it to follow: instructions to the the model produce a more precise outcome than instructions in the prompt.
The model identifies topics, actions, objects, and emotions from the input text you provide, so include the type of tags you want in your instructions. It’s also helpful to provide the number of tags you want the model to produce. You can also specify the number of elements in your instructions.
// Create an instance of the on-device language model's content tagging use case.

```swift
let model = SystemLanguageModel(useCase: .contentTagging)


```
// Initialize a session with the model and instructions.

```swift
let session = LanguageModelSession(model: model, instructions: """
    Provide the two tags that are most significant in the context of topics.
    """
```
)
You don’t need to provide a lot of custom tagging instructions; the content tagging model respects the output format you want, even in the absence of instructions. If you create a generable data type that describes properties with GenerationGuide, you can save context window space by not including custom instructions. If you don’t provide generation guides, the model generates topic-related tags by default.
Note
For very short input queries, topic and emotion tagging instructions provide the best results. Actions or object lists will be too specific, and may repeat the words in the query.
Create a generable type
The content tagging model supports Generable, so you can define a custom data type that the model uses when generating a response. Use maximumCount(_:) on your generable type to enforce a maximum number of tags that you want the model to return. The code below uses Generable guide descriptions to specify the kinds and quantities of tags the model produces:

```swift
@Generable
struct ContentTaggingResult {
    @Guide(
        description: "Most important actions in the input text.",
        .maximumCount(2)
    )
    let actions: [String]


    @Guide(
        description: "Most important emotions in the input text.",
        .maximumCount(3)
    )
    let emotions: [String]


    @Guide(
        description: "Most important objects in the input text.",
        .maximumCount(5)
    )
    let objects: [String]


    @Guide(
        description: "Most important topics in the input text.",
        .maximumCount(2)
    )
    let topics: [String]
}
```
Ideally, match the maximum count you use in your instructions with what you define using the maximumCount(_:) generation guide. If you use a different maximum for each, consider putting the larger maximum in your instructions.
Long queries can produce a large number of actions and objects, so define a maximum count to limit the number of tags. This step helps the model focus on the most relevant parts of long queries, avoids duplicate actions and objects, and improves decoding time.
If you have a complex set of constraints on tagging that are more complicated than the maximum count support of the tagging model, use general instead.
For more information on guided generation, see Generating Swift data structures with guided generation.
Generate a content tagging response
Initialize your session by using the contentTagging model:
// Create an instance of the model with the content tagging use case.

```swift
let model = SystemLanguageModel(useCase: .contentTagging)




```
// Initialize a session with the model.

```swift
let session = LanguageModelSession(model: model)
```
The code below prompts the model to respond about a picnic at the beach with tags like “outdoor activity,” “beach,” and “picnic”:

```swift
let prompt = """
    Today we had a lovely picnic with friends at the beach.
    """
let response = try await session.respond(
    to: prompt,
    generating: ContentTaggingResult.self
```
)
The prompt “Grocery list: 1. Bread flour 2. Salt 3. Instant yeast” prompts the model to respond with the topic “grocery shopping” and includes the objects “grocery list” and “bread flour”.
For some queries, lists may produce the same tag. For example, some topic and emotion tags, like humor, may overlap. When the model produces duplicates, handle it in code, and choose the tag you prefer. When you reuse the same LanguageModelSession, the model may produce tags related to the previous turn or a combination of turns. The model produces what it views as the most important.

## See Also

Getting the content tagging use case
static let contentTagging: SystemLanguageModel.UseCase
A use case for content tagging.



## Type Property

contentTagging
A use case for content tagging.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let contentTagging: SystemLanguageModel.UseCase
```

## Mentioned in


Categorizing and organizing data with content tags

## Discussion

Content tagging produces a list of categorizing tags based on the input prompt. When specializing the model for the contentTagging use case, it always responds with tags. The tagging capabilities of the model include detecting topics, emotions, actions, and objects. For more information about content tagging, see Categorizing and organizing data with content tags.

## See Also

Getting the content tagging use case

Categorizing and organizing data with content tags
Identify topics, actions, objects, and emotions in input text with a content tagging model.



# Structure

SystemLanguageModel.Guardrails
Guardrails flag sensitive content from model input and output.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Guardrails
```

## Mentioned in


Improving the safety of generative model output

## Topics

Getting the guardrail types
static let `default`: SystemLanguageModel.Guardrails
Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a LanguageModelSession.GenerationError.guardrailViolation error.
static let permissiveContentTransformations: SystemLanguageModel.Guardrails
Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.
Handling guardrail errors

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

## Relationships


## Conforms To

- Sendable
- SendableMetatype

## See Also

Loading the model with a use case
convenience init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)
Creates a system language model for a specific use case.

```swift
struct UseCase
```
A type that represents the use case for prompting.



## Type Property

default
Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a LanguageModelSession.GenerationError.guardrailViolation error.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let `default`: SystemLanguageModel.Guardrails
```

## See Also

Getting the guardrail types
static let permissiveContentTransformations: SystemLanguageModel.Guardrails
Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.



## Type Property

permissiveContentTransformations
Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let permissiveContentTransformations: SystemLanguageModel.Guardrails
```

## Mentioned in


Improving the safety of generative model output

## Discussion

In this mode, requests you make to the model that generate a String will not throw LanguageModelSession.GenerationError.guardrailViolation errors. However, when the purpose of your instructions and prompts is not transforming user input, the model may still refuse to respond to potentially unsafe prompts by generating an explanation.
When you generate responses other than String, this mode behaves the same way as .default.

## See Also

Getting the guardrail types
static let `default`: SystemLanguageModel.Guardrails
Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a LanguageModelSession.GenerationError.guardrailViolation error.


Case
LanguageModelSession.GenerationError.guardrailViolation(_:)
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```

## Mentioned in


Improving the safety of generative model output

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.


# Article

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.

## Overview

Use an adapter to adapt the on-device foundation model to fit your specific use case without needing to retrain the entire model from scratch. Before you can load a custom adapter, you first need to train one with an adapter training toolkit. The toolkit uses Python and Pytorch, and requires familiarity with training machine-learning models. After you train an adapter, you can use the toolkit to export a package in the format that Xcode and the Foundation Models framework expects.
When you train an adapter you need to make it available for deployment into your app. An adapter file is large — 160 MB or more — so don’t bundle them in your app. Instead, use App Store Connect, or host the asset on your server, and download the correct adapter for a person’s device on-demand.
Important
Each adapter is compatible with a single specific system model version. You must train a new adapter for every new base model version. A runtime error occurs if your app runs on a person’s device without a compatible adapter.
For more information about the adapter training toolkit, see Get started with Foundation Models adapter training. For more information about asset packs, see Background Assets.
Test a local adapter in Xcode
After you train an adapter with the adapter training toolkit, store your .fmadapter package files in a different directory from your app. Then, open .fmadapter packages with Xcode to locally preview each adapter’s metadata and version compatibility before you deploy the adapter.
If you train multiple adapters:
	0.	Find the adapter package that’s compatible with the macOS version of the Mac on which you run Xcode.
	0.	Select the compatible adapter file in Finder.
	0.	Copy its full file path to the clipboard by pressing Option + Command + C.
	0.	Initialize SystemLanguageModel.Adapter with the file path.
// The absolute path to your adapter.

```swift
let localURL = URL(filePath: "absolute/path/to/my_adapter.fmadapter")


```
// Initialize the adapter by using the local URL.

```swift
let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)
```
After you initialize an Adapter, create an instance of SystemLanguageModel with it:
// An instance of the the system language model using your adapter.

```swift
let customAdapterModel = SystemLanguageModel(adapter: adapter)


```
// Create a session and prompt the model.

```swift
let session = LanguageModelSession(model: customAdapterModel)
let response = try await session.respond(to: "Your prompt here")
```
Important
Only import adapter files into your Xcode project for local testing, then remove them before you publish your app. Adapter files are large, so download them on-demand by using Background Assets.
Testing adapters requires a physical device and isn’t supported on Simulator. When you’re ready to deploy adapters in your app, you need the com.apple.developer.foundation-model-adapter entitlement. You don’t need this entitlement to train or locally test adapters. To request access to use the entitlement, log in to Apple Developer and see Foundation Models Framework Adapter Entitlement.
Bundle adapters as asset packs
When people use your app they only need the specific adapter that’s compatible with their device. Host your adapter assets on a server and use Background Assets to manage downloads. For hosting, you can use your own server or have Apple host your adapter assets. For more information about Apple-hosted asset packs, see Overview of Apple-hosted asset packs.
The Background Assets framework has a type of asset pack specific to adapters that you create for the Foundation Models framework. The Foundation Models adapter training toolkit helps you bundle your adapters in the correct asset pack format. The toolkit uses the ba-package command line tool that’s included with Xcode 16 or later. If you train your adapters on a Linux GPU machine, see How to train adapters to set up a Python environment on your Mac. The adapter toolkit includes example code that shows how to create the asset pack in the correct format.
After you generate an asset pack for each adapter, upload the asset packs to your server. For more information about uploading Apple-hosted adapters, see Upload Apple-Hosted asset packs.
Configure an asset-download target in Xcode
To download adapters at runtime, you need to add an asset-downloader extension target to your Xcode project:
	0.	In Xcode, choose File > New > Target.
	0.	Choose the Background Download template under the Application Extension section.
	0.	Click next.
	0.	Enter a descriptive name, like “AssetDownloader”, for the product name.
	0.	Select the type of extension.
	0.	Click Finish.
The type of extension depends on whether you self-host them or Apple hosts them:
Apple-Hosted, Managed
Apple hosts your adapter assets.
Self-Hosted, Managed
You use your server and make each device’s operating system automatically handle the download life cycle.
Self-Hosted, Unmanaged
You use your server and manage the download life cycle.
After you create an asset-downloader extension target, check that your app target’s info property list contains the required fields specific to your extension type:
Apple-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
- BAUsesAppleHosting = YES
Self-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
If you use Self-Hosted, Unmanaged, then you don’t need additional keys. For more information about configuring background assets with an extension, see Configuring an unmanaged Background Assets project
Choose a compatible adapter at runtime
When you create an asset-downloader extension, Xcode generates a Swift file — BackgroundDownloadHandler.swift — that Background Assets uses to download your adapters. Open the Swift file in Xcode and fill in the code based on your target type. For Apple-Hosted, Managed or Self-Hosted, Managed extension types, complete the function shouldDownload with the following code that chooses an adapter asset compatible with the runtime device:

```swift
func shouldDownload(_ assetPack: AssetPack) -> Bool {
    // Check for any non-adapter assets your app has, like shaders. Remove the
    // check if your app doesn't have any non-adapter assets.
    if assetPack.id.hasPrefix("mygameshader") {
        // Return false to filter out asset packs, or true to allow download.
        return true
    }


    // Use the Foundation Models framework to check adapter compatibility with the runtime device.
    return SystemLanguageModel.Adapter.isCompatible(assetPack)
}
```
If your extension type is Self-Hosted, Unmanaged, the file Xcode generates has many functions in it for manual control over the download life cycle of your assets.
Load adapter assets in your app
After you configure an asset-downloader extension, you can start loading adapters. Before you download an adapter, remove any outdated adapters that might be on a person’s device:
SystemLanguageModel.Adapter.removeObsoleteAdapters()
Create an instance of SystemLanguageModel.Adapter using your adapter’s base name, but exclude the file extension. If a person’s device doesn’t have a compatible adapter downloaded, your asset-downloader extension starts downloading a compatible adapter asset pack:

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")
```
Initializing a SystemLanguageModel.Adapter starts a download automatically when a person launches your app for the first time or their device needs an updated adapter. Because adapters can have a large data size they can take some time to download, especially if a person is on Wi-Fi or a cell network. If a person doesn’t have a network connection, they aren’t able to use your adapter right away. This method shows how to track the download status of an adapter:

```swift
func checkAdapterDownload(name: String) async -> Bool {
    // Get the ID of the compatible adapter.
    let assetpackIDList = SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(
        name: name
    )


    if let assetPackID = assetpackIDList.first {
        // Get the download status asynchronous sequence.
        let statusUpdates = AssetPackManager.shared.statusUpdates(forAssetPackWithID: assetPackID)


        // Use the current status to update any loading UI.
        for await status in statusUpdates {
            switch status {
            case .began(let assetPack):
                // The download started.
            case .paused(let assetPack):
                // The download is in a paused state.
            case .downloading(let assetPack, let progress):
                // The download in progress.
            case .finished(let assetPack):
                // The download is complete and the adapter is ready to use.
                return true
            case .failed(let assetPack, let error):
                // The download failed.
                return false
            @unknown default:
                // The download encountered an unknown status.
                fatalError()
            }
        }
    }
}
```
For more details on tracking downloads for general assets, see Downloading Apple-hosted asset packs.
Before you attempt to use the adapter, you need to wait for the status to be in a AssetPackManager.DownloadStatusUpdate.finished(_:) state. The system returns AssetPackManager.DownloadStatusUpdate.finished(_:) immediately if no download is necessary.
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    // Adapt the base model with your adapter.
    let adaptedModel = SystemLanguageModel(adapter: adapter)
    
    // Start a session with the adapted model.
    let session = LanguageModelSession(model: adaptedModel)
    
    // Start prompting the adapted model.
}
```
Compile your draft model
A draft model is an optional step when training your adapter that can speed up inference. If your adapter includes a draft model, you can compile it for faster inference:
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    do {
        // You can use your adapter without compiling the draft model, or during
        // compilation, but running inference with your adapter might be slower.
        try await adapter.compile()
    } catch let error {
        // Handle the draft model compilation error.
    }
}
```
For more about training draft models, see the “Optionally train the draft model” section in Get started with Foundation Models adapter training.
Compiling a draft model is a computationally expensive step, so use the Background Tasks framework to configure a background task for your app. In your background task, call compile() on your adapter to start compilation. For more information about using background tasks, see Using background tasks to update your app.
Compilation doesn’t run every time a person uses your app:
- The first time a device downloads a new version of your adapter, a call to compile() fully compiles your draft model and saves it to the device.
- During subsequent launches of your app, a call to compile() checks for a saved compiled draft model and returns it immediately if it exists.
Important
Rate limiting protects device resources that are shared between all apps and processes. If the framework determines that a new compilation is necessary, it rate-limits the compilation process on all platforms, excluding macOS, to three draft model compilations per-app, per-day.
The full compilation process runs every time you launch your app through Xcode because Xcode assigns your app a new UUID for every launch. If you receive a rate-limiting error while testing your app, stop your app in Xcode and re-launch it to reset the rate counter.

## See Also

Loading the model with an adapter
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.


Property List Key
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
> iOS 26.0+
> iPadOS 26.0+
> macOS 26.0+
> visionOS 26.0+

## Details

Type
boolean
Attributes
Default: NO

## Discussion

Before submitting an app with this entitlement to the App Store, you must get permission to use the entitlement. To apply for the entitlement, log in to your Apple Developer Account with an Account Holder role and fill out the request form.


## Initializer


```swift
init(adapter:guardrails:)
```
Creates the base version of the model with an adapter.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
convenience init(
    adapter: SystemLanguageModel.Adapter,
    guardrails: SystemLanguageModel.Guardrails = .default
```
)

## See Also

Loading the model with an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.



# Structure

SystemLanguageModel.Adapter
Specializes the system language model for custom use cases.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Adapter
```

## Mentioned in


Loading and using a custom adapter with Foundation Models

## Overview

Use the base system model for most prompt engineering, guided generation, and tools. If you need to specialize the model, train a custom Adapter to alter the system model weights and optimize it for your custom task. Use custom adapters only if you’re comfortable training foundation models in Python.
Important
Be sure to re-train the adapter for every new version of the base system model that Apple releases. Adapters consume a large amount of storage space and isn’t recommended for most apps.
For more on custom adapters, see Get started with Foundation Models adapter training.

## Topics

Creating an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
init(fileURL: URL) throws
```
Creates an adapter from the file URL.

```swift
init(name: String) throws
```
Creates an adapter downloaded from the background assets framework.
Prepare the adapter

```swift
func compile() async throws
```
Prepares an adapter before being used with a LanguageModelSession. You should call this if your adapter has a draft model.
Getting the metadata

```swift
var creatorDefinedMetadata: [String : Any]
```
Values read from the creator defined field of the adapter’s metadata.
Removing obsolete adapters
static func removeObsoleteAdapters() throws
Remove all obsolete adapters that are no longer compatible with current system models.
Checking compatibility
static func compatibleAdapterIdentifiers(name: String) -> [String]
Get all compatible adapter identifiers compatible with current system models.
static func isCompatible(AssetPack) -> Bool
Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.
Getting the asset error

```swift
enum AssetError
```

## See Also

Loading the model with an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.



# Article

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.

## Overview

Use an adapter to adapt the on-device foundation model to fit your specific use case without needing to retrain the entire model from scratch. Before you can load a custom adapter, you first need to train one with an adapter training toolkit. The toolkit uses Python and Pytorch, and requires familiarity with training machine-learning models. After you train an adapter, you can use the toolkit to export a package in the format that Xcode and the Foundation Models framework expects.
When you train an adapter you need to make it available for deployment into your app. An adapter file is large — 160 MB or more — so don’t bundle them in your app. Instead, use App Store Connect, or host the asset on your server, and download the correct adapter for a person’s device on-demand.
Important
Each adapter is compatible with a single specific system model version. You must train a new adapter for every new base model version. A runtime error occurs if your app runs on a person’s device without a compatible adapter.
For more information about the adapter training toolkit, see Get started with Foundation Models adapter training. For more information about asset packs, see Background Assets.
Test a local adapter in Xcode
After you train an adapter with the adapter training toolkit, store your .fmadapter package files in a different directory from your app. Then, open .fmadapter packages with Xcode to locally preview each adapter’s metadata and version compatibility before you deploy the adapter.
If you train multiple adapters:
	0.	Find the adapter package that’s compatible with the macOS version of the Mac on which you run Xcode.
	0.	Select the compatible adapter file in Finder.
	0.	Copy its full file path to the clipboard by pressing Option + Command + C.
	0.	Initialize SystemLanguageModel.Adapter with the file path.
// The absolute path to your adapter.

```swift
let localURL = URL(filePath: "absolute/path/to/my_adapter.fmadapter")


```
// Initialize the adapter by using the local URL.

```swift
let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)
```
After you initialize an Adapter, create an instance of SystemLanguageModel with it:
// An instance of the the system language model using your adapter.

```swift
let customAdapterModel = SystemLanguageModel(adapter: adapter)


```
// Create a session and prompt the model.

```swift
let session = LanguageModelSession(model: customAdapterModel)
let response = try await session.respond(to: "Your prompt here")
```
Important
Only import adapter files into your Xcode project for local testing, then remove them before you publish your app. Adapter files are large, so download them on-demand by using Background Assets.
Testing adapters requires a physical device and isn’t supported on Simulator. When you’re ready to deploy adapters in your app, you need the com.apple.developer.foundation-model-adapter entitlement. You don’t need this entitlement to train or locally test adapters. To request access to use the entitlement, log in to Apple Developer and see Foundation Models Framework Adapter Entitlement.
Bundle adapters as asset packs
When people use your app they only need the specific adapter that’s compatible with their device. Host your adapter assets on a server and use Background Assets to manage downloads. For hosting, you can use your own server or have Apple host your adapter assets. For more information about Apple-hosted asset packs, see Overview of Apple-hosted asset packs.
The Background Assets framework has a type of asset pack specific to adapters that you create for the Foundation Models framework. The Foundation Models adapter training toolkit helps you bundle your adapters in the correct asset pack format. The toolkit uses the ba-package command line tool that’s included with Xcode 16 or later. If you train your adapters on a Linux GPU machine, see How to train adapters to set up a Python environment on your Mac. The adapter toolkit includes example code that shows how to create the asset pack in the correct format.
After you generate an asset pack for each adapter, upload the asset packs to your server. For more information about uploading Apple-hosted adapters, see Upload Apple-Hosted asset packs.
Configure an asset-download target in Xcode
To download adapters at runtime, you need to add an asset-downloader extension target to your Xcode project:
	0.	In Xcode, choose File > New > Target.
	0.	Choose the Background Download template under the Application Extension section.
	0.	Click next.
	0.	Enter a descriptive name, like “AssetDownloader”, for the product name.
	0.	Select the type of extension.
	0.	Click Finish.
The type of extension depends on whether you self-host them or Apple hosts them:
Apple-Hosted, Managed
Apple hosts your adapter assets.
Self-Hosted, Managed
You use your server and make each device’s operating system automatically handle the download life cycle.
Self-Hosted, Unmanaged
You use your server and manage the download life cycle.
After you create an asset-downloader extension target, check that your app target’s info property list contains the required fields specific to your extension type:
Apple-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
- BAUsesAppleHosting = YES
Self-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
If you use Self-Hosted, Unmanaged, then you don’t need additional keys. For more information about configuring background assets with an extension, see Configuring an unmanaged Background Assets project
Choose a compatible adapter at runtime
When you create an asset-downloader extension, Xcode generates a Swift file — BackgroundDownloadHandler.swift — that Background Assets uses to download your adapters. Open the Swift file in Xcode and fill in the code based on your target type. For Apple-Hosted, Managed or Self-Hosted, Managed extension types, complete the function shouldDownload with the following code that chooses an adapter asset compatible with the runtime device:

```swift
func shouldDownload(_ assetPack: AssetPack) -> Bool {
    // Check for any non-adapter assets your app has, like shaders. Remove the
    // check if your app doesn't have any non-adapter assets.
    if assetPack.id.hasPrefix("mygameshader") {
        // Return false to filter out asset packs, or true to allow download.
        return true
    }


    // Use the Foundation Models framework to check adapter compatibility with the runtime device.
    return SystemLanguageModel.Adapter.isCompatible(assetPack)
}
```
If your extension type is Self-Hosted, Unmanaged, the file Xcode generates has many functions in it for manual control over the download life cycle of your assets.
Load adapter assets in your app
After you configure an asset-downloader extension, you can start loading adapters. Before you download an adapter, remove any outdated adapters that might be on a person’s device:
SystemLanguageModel.Adapter.removeObsoleteAdapters()
Create an instance of SystemLanguageModel.Adapter using your adapter’s base name, but exclude the file extension. If a person’s device doesn’t have a compatible adapter downloaded, your asset-downloader extension starts downloading a compatible adapter asset pack:

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")
```
Initializing a SystemLanguageModel.Adapter starts a download automatically when a person launches your app for the first time or their device needs an updated adapter. Because adapters can have a large data size they can take some time to download, especially if a person is on Wi-Fi or a cell network. If a person doesn’t have a network connection, they aren’t able to use your adapter right away. This method shows how to track the download status of an adapter:

```swift
func checkAdapterDownload(name: String) async -> Bool {
    // Get the ID of the compatible adapter.
    let assetpackIDList = SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(
        name: name
    )


    if let assetPackID = assetpackIDList.first {
        // Get the download status asynchronous sequence.
        let statusUpdates = AssetPackManager.shared.statusUpdates(forAssetPackWithID: assetPackID)


        // Use the current status to update any loading UI.
        for await status in statusUpdates {
            switch status {
            case .began(let assetPack):
                // The download started.
            case .paused(let assetPack):
                // The download is in a paused state.
            case .downloading(let assetPack, let progress):
                // The download in progress.
            case .finished(let assetPack):
                // The download is complete and the adapter is ready to use.
                return true
            case .failed(let assetPack, let error):
                // The download failed.
                return false
            @unknown default:
                // The download encountered an unknown status.
                fatalError()
            }
        }
    }
}
```
For more details on tracking downloads for general assets, see Downloading Apple-hosted asset packs.
Before you attempt to use the adapter, you need to wait for the status to be in a AssetPackManager.DownloadStatusUpdate.finished(_:) state. The system returns AssetPackManager.DownloadStatusUpdate.finished(_:) immediately if no download is necessary.
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    // Adapt the base model with your adapter.
    let adaptedModel = SystemLanguageModel(adapter: adapter)
    
    // Start a session with the adapted model.
    let session = LanguageModelSession(model: adaptedModel)
    
    // Start prompting the adapted model.
}
```
Compile your draft model
A draft model is an optional step when training your adapter that can speed up inference. If your adapter includes a draft model, you can compile it for faster inference:
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    do {
        // You can use your adapter without compiling the draft model, or during
        // compilation, but running inference with your adapter might be slower.
        try await adapter.compile()
    } catch let error {
        // Handle the draft model compilation error.
    }
}
```
For more about training draft models, see the “Optionally train the draft model” section in Get started with Foundation Models adapter training.
Compiling a draft model is a computationally expensive step, so use the Background Tasks framework to configure a background task for your app. In your background task, call compile() on your adapter to start compilation. For more information about using background tasks, see Using background tasks to update your app.
Compilation doesn’t run every time a person uses your app:
- The first time a device downloads a new version of your adapter, a call to compile() fully compiles your draft model and saves it to the device.
- During subsequent launches of your app, a call to compile() checks for a saved compiled draft model and returns it immediately if it exists.
Important
Rate limiting protects device resources that are shared between all apps and processes. If the framework determines that a new compilation is necessary, it rate-limits the compilation process on all platforms, excluding macOS, to three draft model compilations per-app, per-day.
The full compilation process runs every time you launch your app through Xcode because Xcode assigns your app a new UUID for every launch. If you receive a rate-limiting error while testing your app, stop your app in Xcode and re-launch it to reset the rate counter.

## See Also

Loading the model with an adapter
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.



## Initializer


```swift
init(adapter:guardrails:)
```
Creates the base version of the model with an adapter.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
convenience init(
    adapter: SystemLanguageModel.Adapter,
    guardrails: SystemLanguageModel.Guardrails = .default
```
)

## See Also

Loading the model with an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.



# Structure

SystemLanguageModel.Adapter
Specializes the system language model for custom use cases.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Adapter
```

## Mentioned in


Loading and using a custom adapter with Foundation Models

## Overview

Use the base system model for most prompt engineering, guided generation, and tools. If you need to specialize the model, train a custom Adapter to alter the system model weights and optimize it for your custom task. Use custom adapters only if you’re comfortable training foundation models in Python.
Important
Be sure to re-train the adapter for every new version of the base system model that Apple releases. Adapters consume a large amount of storage space and isn’t recommended for most apps.
For more on custom adapters, see Get started with Foundation Models adapter training.

## Topics

Creating an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
init(fileURL: URL) throws
```
Creates an adapter from the file URL.

```swift
init(name: String) throws
```
Creates an adapter downloaded from the background assets framework.
Prepare the adapter

```swift
func compile() async throws
```
Prepares an adapter before being used with a LanguageModelSession. You should call this if your adapter has a draft model.
Getting the metadata

```swift
var creatorDefinedMetadata: [String : Any]
```
Values read from the creator defined field of the adapter’s metadata.
Removing obsolete adapters
static func removeObsoleteAdapters() throws
Remove all obsolete adapters that are no longer compatible with current system models.
Checking compatibility
static func compatibleAdapterIdentifiers(name: String) -> [String]
Get all compatible adapter identifiers compatible with current system models.
static func isCompatible(AssetPack) -> Bool
Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.
Getting the asset error

```swift
enum AssetError
```

## See Also

Loading the model with an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.



# Article

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.

## Overview

Use an adapter to adapt the on-device foundation model to fit your specific use case without needing to retrain the entire model from scratch. Before you can load a custom adapter, you first need to train one with an adapter training toolkit. The toolkit uses Python and Pytorch, and requires familiarity with training machine-learning models. After you train an adapter, you can use the toolkit to export a package in the format that Xcode and the Foundation Models framework expects.
When you train an adapter you need to make it available for deployment into your app. An adapter file is large — 160 MB or more — so don’t bundle them in your app. Instead, use App Store Connect, or host the asset on your server, and download the correct adapter for a person’s device on-demand.
Important
Each adapter is compatible with a single specific system model version. You must train a new adapter for every new base model version. A runtime error occurs if your app runs on a person’s device without a compatible adapter.
For more information about the adapter training toolkit, see Get started with Foundation Models adapter training. For more information about asset packs, see Background Assets.
Test a local adapter in Xcode
After you train an adapter with the adapter training toolkit, store your .fmadapter package files in a different directory from your app. Then, open .fmadapter packages with Xcode to locally preview each adapter’s metadata and version compatibility before you deploy the adapter.
If you train multiple adapters:
	0.	Find the adapter package that’s compatible with the macOS version of the Mac on which you run Xcode.
	0.	Select the compatible adapter file in Finder.
	0.	Copy its full file path to the clipboard by pressing Option + Command + C.
	0.	Initialize SystemLanguageModel.Adapter with the file path.
// The absolute path to your adapter.

```swift
let localURL = URL(filePath: "absolute/path/to/my_adapter.fmadapter")


```
// Initialize the adapter by using the local URL.

```swift
let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)
```
After you initialize an Adapter, create an instance of SystemLanguageModel with it:
// An instance of the the system language model using your adapter.

```swift
let customAdapterModel = SystemLanguageModel(adapter: adapter)


```
// Create a session and prompt the model.

```swift
let session = LanguageModelSession(model: customAdapterModel)
let response = try await session.respond(to: "Your prompt here")
```
Important
Only import adapter files into your Xcode project for local testing, then remove them before you publish your app. Adapter files are large, so download them on-demand by using Background Assets.
Testing adapters requires a physical device and isn’t supported on Simulator. When you’re ready to deploy adapters in your app, you need the com.apple.developer.foundation-model-adapter entitlement. You don’t need this entitlement to train or locally test adapters. To request access to use the entitlement, log in to Apple Developer and see Foundation Models Framework Adapter Entitlement.
Bundle adapters as asset packs
When people use your app they only need the specific adapter that’s compatible with their device. Host your adapter assets on a server and use Background Assets to manage downloads. For hosting, you can use your own server or have Apple host your adapter assets. For more information about Apple-hosted asset packs, see Overview of Apple-hosted asset packs.
The Background Assets framework has a type of asset pack specific to adapters that you create for the Foundation Models framework. The Foundation Models adapter training toolkit helps you bundle your adapters in the correct asset pack format. The toolkit uses the ba-package command line tool that’s included with Xcode 16 or later. If you train your adapters on a Linux GPU machine, see How to train adapters to set up a Python environment on your Mac. The adapter toolkit includes example code that shows how to create the asset pack in the correct format.
After you generate an asset pack for each adapter, upload the asset packs to your server. For more information about uploading Apple-hosted adapters, see Upload Apple-Hosted asset packs.
Configure an asset-download target in Xcode
To download adapters at runtime, you need to add an asset-downloader extension target to your Xcode project:
	0.	In Xcode, choose File > New > Target.
	0.	Choose the Background Download template under the Application Extension section.
	0.	Click next.
	0.	Enter a descriptive name, like “AssetDownloader”, for the product name.
	0.	Select the type of extension.
	0.	Click Finish.
The type of extension depends on whether you self-host them or Apple hosts them:
Apple-Hosted, Managed
Apple hosts your adapter assets.
Self-Hosted, Managed
You use your server and make each device’s operating system automatically handle the download life cycle.
Self-Hosted, Unmanaged
You use your server and manage the download life cycle.
After you create an asset-downloader extension target, check that your app target’s info property list contains the required fields specific to your extension type:
Apple-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
- BAUsesAppleHosting = YES
Self-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
If you use Self-Hosted, Unmanaged, then you don’t need additional keys. For more information about configuring background assets with an extension, see Configuring an unmanaged Background Assets project
Choose a compatible adapter at runtime
When you create an asset-downloader extension, Xcode generates a Swift file — BackgroundDownloadHandler.swift — that Background Assets uses to download your adapters. Open the Swift file in Xcode and fill in the code based on your target type. For Apple-Hosted, Managed or Self-Hosted, Managed extension types, complete the function shouldDownload with the following code that chooses an adapter asset compatible with the runtime device:

```swift
func shouldDownload(_ assetPack: AssetPack) -> Bool {
    // Check for any non-adapter assets your app has, like shaders. Remove the
    // check if your app doesn't have any non-adapter assets.
    if assetPack.id.hasPrefix("mygameshader") {
        // Return false to filter out asset packs, or true to allow download.
        return true
    }


    // Use the Foundation Models framework to check adapter compatibility with the runtime device.
    return SystemLanguageModel.Adapter.isCompatible(assetPack)
}
```
If your extension type is Self-Hosted, Unmanaged, the file Xcode generates has many functions in it for manual control over the download life cycle of your assets.
Load adapter assets in your app
After you configure an asset-downloader extension, you can start loading adapters. Before you download an adapter, remove any outdated adapters that might be on a person’s device:
SystemLanguageModel.Adapter.removeObsoleteAdapters()
Create an instance of SystemLanguageModel.Adapter using your adapter’s base name, but exclude the file extension. If a person’s device doesn’t have a compatible adapter downloaded, your asset-downloader extension starts downloading a compatible adapter asset pack:

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")
```
Initializing a SystemLanguageModel.Adapter starts a download automatically when a person launches your app for the first time or their device needs an updated adapter. Because adapters can have a large data size they can take some time to download, especially if a person is on Wi-Fi or a cell network. If a person doesn’t have a network connection, they aren’t able to use your adapter right away. This method shows how to track the download status of an adapter:

```swift
func checkAdapterDownload(name: String) async -> Bool {
    // Get the ID of the compatible adapter.
    let assetpackIDList = SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(
        name: name
    )


    if let assetPackID = assetpackIDList.first {
        // Get the download status asynchronous sequence.
        let statusUpdates = AssetPackManager.shared.statusUpdates(forAssetPackWithID: assetPackID)


        // Use the current status to update any loading UI.
        for await status in statusUpdates {
            switch status {
            case .began(let assetPack):
                // The download started.
            case .paused(let assetPack):
                // The download is in a paused state.
            case .downloading(let assetPack, let progress):
                // The download in progress.
            case .finished(let assetPack):
                // The download is complete and the adapter is ready to use.
                return true
            case .failed(let assetPack, let error):
                // The download failed.
                return false
            @unknown default:
                // The download encountered an unknown status.
                fatalError()
            }
        }
    }
}
```
For more details on tracking downloads for general assets, see Downloading Apple-hosted asset packs.
Before you attempt to use the adapter, you need to wait for the status to be in a AssetPackManager.DownloadStatusUpdate.finished(_:) state. The system returns AssetPackManager.DownloadStatusUpdate.finished(_:) immediately if no download is necessary.
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    // Adapt the base model with your adapter.
    let adaptedModel = SystemLanguageModel(adapter: adapter)
    
    // Start a session with the adapted model.
    let session = LanguageModelSession(model: adaptedModel)
    
    // Start prompting the adapted model.
}
```
Compile your draft model
A draft model is an optional step when training your adapter that can speed up inference. If your adapter includes a draft model, you can compile it for faster inference:
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    do {
        // You can use your adapter without compiling the draft model, or during
        // compilation, but running inference with your adapter might be slower.
        try await adapter.compile()
    } catch let error {
        // Handle the draft model compilation error.
    }
}
```
For more about training draft models, see the “Optionally train the draft model” section in Get started with Foundation Models adapter training.
Compiling a draft model is a computationally expensive step, so use the Background Tasks framework to configure a background task for your app. In your background task, call compile() on your adapter to start compilation. For more information about using background tasks, see Using background tasks to update your app.
Compilation doesn’t run every time a person uses your app:
- The first time a device downloads a new version of your adapter, a call to compile() fully compiles your draft model and saves it to the device.
- During subsequent launches of your app, a call to compile() checks for a saved compiled draft model and returns it immediately if it exists.
Important
Rate limiting protects device resources that are shared between all apps and processes. If the framework determines that a new compilation is necessary, it rate-limits the compilation process on all platforms, excluding macOS, to three draft model compilations per-app, per-day.
The full compilation process runs every time you launch your app through Xcode because Xcode assigns your app a new UUID for every launch. If you receive a rate-limiting error while testing your app, stop your app in Xcode and re-launch it to reset the rate counter.

## See Also

Loading the model with an adapter
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.


Property List Key
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
> iOS 26.0+
> iPadOS 26.0+
> macOS 26.0+
> visionOS 26.0+

## Details

Type
boolean
Attributes
Default: NO

## Discussion

Before submitting an app with this entitlement to the App Store, you must get permission to use the entitlement. To apply for the entitlement, log in to your Apple Developer Account with an Account Holder role and fill out the request form.



```swift
init(fileURL:)
```
Creates an adapter from the file URL.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(fileURL: URL) throws
```

## Discussion


## Throws

An error of AssetLoadingError type when fileURL is invalid.

## See Also

Creating an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
init(name: String) throws
```
Creates an adapter downloaded from the background assets framework.



## Initializer


```swift
init(name:)
```
Creates an adapter downloaded from the background assets framework.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(name: String) throws
```

## Discussion


## Throws

An error of AssetLoadingError type when there are no compatible asset packs with this adapter name downloaded.

## See Also

Creating an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
init(fileURL: URL) throws
```
Creates an adapter from the file URL.


## Instance Method

compile()
Prepares an adapter before being used with a LanguageModelSession. You should call this if your adapter has a draft model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
func compile() async throws
```

## Mentioned in


Loading and using a custom adapter with Foundation Models


## Instance Property

creatorDefinedMetadata
Values read from the creator defined field of the adapter’s metadata.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var creatorDefinedMetadata: [String : Any] { get }


```

## Type Method

removeObsoleteAdapters()
Remove all obsolete adapters that are no longer compatible with current system models.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func removeObsoleteAdapters() throws



## Type Method

compatibleAdapterIdentifiers(name:)
Get all compatible adapter identifiers compatible with current system models.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func compatibleAdapterIdentifiers(name: String) -> [String]

## Parameters

name
Name of the adapter.

## Return Value

All adapter identifiers compatible with current system models, listed in descending order in terms of system preference. You can determine which asset pack or on-demand resource to download with compatible adapter identifiers.
On devices that support Apple Intelligence, the result is guaranteed to be non-empty.

## See Also

Checking compatibility
static func isCompatible(AssetPack) -> Bool
Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.



## Type Method

isCompatible(_:)
Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func isCompatible(_ assetPack: AssetPack) -> Bool

## Discussion

Use this check when choosing an adapter asset pack to download. This check only validates the asset pack name and metadata, so initializing the adapter with init(name:) — or loading the adapter onto the base model with init(adapter:guardrails:) — may throw errors if the adapter has a compatibility issue despite having correct metadata.
Note
Run this check before you download an adapter asset pack to confirm if it’s usable on the runtime device.

## See Also

Checking compatibility
static func compatibleAdapterIdentifiers(name: String) -> [String]
Get all compatible adapter identifiers compatible with current system models.



# Enumeration

SystemLanguageModel.Adapter.AssetError
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum AssetError
```

## Topics

Getting the asset errors

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if there are no compatible adapters for the current system base model.

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided adapter name is invalid.

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided asset files are invalid.

```swift
struct Context
```
The context in which the error occurred.
Getting the error description

```swift
var errorDescription: String?
```
A string representation of the error description.

## Relationships


## Conforms To

- Error
- LocalizedError
- Sendable
- SendableMetatype


Case
SystemLanguageModel.Adapter.AssetError.compatibleAdapterNotFound(_:)
An error that happens if there are no compatible adapters for the current system base model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```

## See Also

Getting the asset errors

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided adapter name is invalid.

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided asset files are invalid.

```swift
struct Context
```
The context in which the error occurred.


Case
SystemLanguageModel.Adapter.AssetError.invalidAdapterName(_:)
An error that happens if the provided adapter name is invalid.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```

## See Also

Getting the asset errors

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if there are no compatible adapters for the current system base model.

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided asset files are invalid.

```swift
struct Context
```
The context in which the error occurred.


Case
SystemLanguageModel.Adapter.AssetError.invalidAsset(_:)
An error that happens if the provided asset files are invalid.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```

## See Also

Getting the asset errors

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if there are no compatible adapters for the current system base model.

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided adapter name is invalid.

```swift
struct Context
```
The context in which the error occurred.



# Structure

SystemLanguageModel.Adapter.AssetError.Context
The context in which the error occurred.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Context
```

## Topics

Creating a context

```swift
init(debugDescription: String)
```
Getting the debug description

```swift
let debugDescription: String
```
A debug description to help developers diagnose issues during development.

## Relationships


## Conforms To

- Sendable
- SendableMetatype

## See Also

Getting the asset errors

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if there are no compatible adapters for the current system base model.

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided adapter name is invalid.

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided asset files are invalid.



## Initializer


```swift
init(debugDescription:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(debugDescription: String)


```

## Instance Property

debugDescription
A debug description to help developers diagnose issues during development.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
let debugDescription: String
```

## Discussion

This string is not localized and is not appropriate for display to end users.



## Instance Property

errorDescription
A string representation of the error description.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var errorDescription: String? { get }


```

## Instance Property

isAvailable
A convenience getter to check if the system is entirely ready.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
final var isAvailable: Bool { get }
```

## See Also

Checking model availability

```swift
var availability: SystemLanguageModel.Availability
```
The availability of the language model.

```swift
enum Availability
```
The availability status for a specific system language model.



## Instance Property

availability
The availability of the language model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
final var availability: SystemLanguageModel.Availability { get }
```

## See Also

Checking model availability

```swift
var isAvailable: Bool
```
A convenience getter to check if the system is entirely ready.

```swift
enum Availability
```
The availability status for a specific system language model.



# Enumeration

SystemLanguageModel.Availability
The availability status for a specific system language model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@frozen
enum Availability
```

## Overview


## See Also

availability

## Topics

Checking for availability

```swift
case available
```
The system is ready for making requests.

```swift
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```
Indicates that the system is not ready for requests.

```swift
enum UnavailableReason
```
The unavailable reason.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Checking model availability

```swift
var isAvailable: Bool
```
A convenience getter to check if the system is entirely ready.

```swift
var availability: SystemLanguageModel.Availability
```
The availability of the language model.


Case
SystemLanguageModel.Availability.available
The system is ready for making requests.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case available
```

## See Also

Checking for availability

```swift
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```
Indicates that the system is not ready for requests.

```swift
enum UnavailableReason
```
The unavailable reason.


Case
SystemLanguageModel.Availability.unavailable(_:)
Indicates that the system is not ready for requests.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```

## See Also

Checking for availability

```swift
case available
```
The system is ready for making requests.

```swift
enum UnavailableReason
```
The unavailable reason.



# Enumeration

SystemLanguageModel.Availability.UnavailableReason
The unavailable reason.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum UnavailableReason
```

## Topics

Getting the unavailable reasons

```swift
case appleIntelligenceNotEnabled
```
Apple Intelligence is not enabled on the system.

```swift
case deviceNotEligible
```
The device does not support Apple Intelligence.

```swift
case modelNotReady
```
The model(s) aren’t available on the user’s device.

## Relationships


## Conforms To

- Copyable
- Equatable
- Hashable
- Sendable
- SendableMetatype

## See Also

Checking for availability

```swift
case available
```
The system is ready for making requests.

```swift
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```
Indicates that the system is not ready for requests.

Case
SystemLanguageModel.Availability.UnavailableReason.appleIntelligenceNotEnabled
Apple Intelligence is not enabled on the system.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case appleIntelligenceNotEnabled
```

## See Also

Getting the unavailable reasons

```swift
case deviceNotEligible
```
The device does not support Apple Intelligence.

```swift
case modelNotReady
```
The model(s) aren’t available on the user’s device.


Case
SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible
The device does not support Apple Intelligence.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case deviceNotEligible
```

## See Also

Getting the unavailable reasons

```swift
case appleIntelligenceNotEnabled
```
Apple Intelligence is not enabled on the system.

```swift
case modelNotReady
```
The model(s) aren’t available on the user’s device.

Case
SystemLanguageModel.Availability.UnavailableReason.modelNotReady
The model(s) aren’t available on the user’s device.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case modelNotReady
```

## Discussion

Models are downloaded automatically based on factors like network status, battery level, and system load.

## See Also

Getting the unavailable reasons

```swift
case appleIntelligenceNotEnabled
```
Apple Intelligence is not enabled on the system.

```swift
case deviceNotEligible
```
The device does not support Apple Intelligence.



## Instance Property

supportedLanguages
Languages that the model supports.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
final var supportedLanguages: Set<Locale.Language> { get }
```

## Mentioned in


Supporting languages and locales with Foundation Models

## Discussion

To check if a given locale is considered supported by the model, use supportsLocale(_:), which will also take into consideration language fallbacks.


## Instance Method

supportsLocale(_:)
Returns a Boolean indicating whether the given locale is supported by the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final func supportsLocale(_ locale: Locale = Locale.current) -> Bool

## Mentioned in


Supporting languages and locales with Foundation Models

## Discussion

Use this method over supportedLanguages to check whether the given locale qualifies a user for using this model, as this method will take into consideration language fallbacks.



## Type Property

default
The base version of the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let `default`: SystemLanguageModel
```

## Mentioned in


Generating content and performing tasks with Foundation Models

## Discussion

The base model is a generic model that is useful for a wide variety of applications, but is not specialized to any particular use case.



# Structure

SystemLanguageModel.UseCase
A type that represents the use case for prompting.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct UseCase
```

## Topics

Getting the general use case

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.
static let general: SystemLanguageModel.UseCase
A use case for general prompting.
Getting the content tagging use case

Categorizing and organizing data with content tags
Identify topics, actions, objects, and emotions in input text with a content tagging model.
static let contentTagging: SystemLanguageModel.UseCase
A use case for content tagging.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Essentials

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.



# Article

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

## Overview

The Foundation Models framework lets you tap into the on-device large models at the core of Apple Intelligence. You can enhance your app by using generative models to create content or perform tasks. The framework supports language understanding and generation based on model capabilities.
For design guidance, see Human Interface Guidelines > Technologies > Generative AI.
Understand model capabilities
When considering features for your app, it helps to know what the on-device language model can do. The on-device model supports text generation and understanding that you can use to:
Capability
Prompt example
Summarize
“Summarize this article.”
Extract entities
“List the people and places mentioned in this text.”
Understand text
“What happens to the dog in this story?”
Refine or edit text
“Change this story to be in second person.”
Classify or judge text
“Is this text relevant to the topic ‘Swift’?”
Compose creative writing
“Generate a short bedtime story about a fox.”
Generate tags from text
“Provide two tags that describe the main topics of this text.”
Generate game dialog
“Respond in the voice of a friendly inn keeper.”
The on-device language model may not be suitable for handling all requests, like:
Capabilities to avoid
Prompt example
Do basic math
“How many b’s are there in bagel?”
Create code
“Generate a Swift navigation list.”
Perform logical reasoning
“If I’m at Apple Park facing Canada, what direction is Texas?”
The model can complete complex generative tasks when you use guided generation or tool calling. For more on handling complex tasks, or tasks that require extensive world-knowledge, see Generating Swift data structures with guided generation and Expanding generation with tool calling.
Check for availability
Before you use the on-device model in your app, check that the model is available by creating an instance of SystemLanguageModel with the default property.
Model availability depends on device factors like:
- The device must support Apple Intelligence.
- The device must have Apple Intelligence turned on in Settings.
Note
It can take some time for the model to download and become available when a person turns on Apple Intelligence.
Always verify model availability first, and plan for a fallback experience in case the model is unavailable.

```swift
struct GenerativeView: View {
    // Create a reference to the system language model.
    private var model = SystemLanguageModel.default


    var body: some View {
        switch model.availability {
        case .available:
            // Show your intelligence UI.
        case .unavailable(.deviceNotEligible):
            // Show an alternative UI.
        case .unavailable(.appleIntelligenceNotEnabled):
            // Ask the person to turn on Apple Intelligence.
        case .unavailable(.modelNotReady):
            // The model isn't ready because it's downloading or because of other system reasons.
        case .unavailable(let other):
            // The model is unavailable for an unknown reason.
        }
    }
}
```
Create a session
After confirming that the model is available, create a LanguageModelSession object to call the model. For a single-turn interaction, create a new session each time you call the model:
// Create a session with the system model.

```swift
let session = LanguageModelSession()
```
For a multiturn interaction — where the model retains some knowledge of what it produced — reuse the same session each time you call the model.
Provide a prompt to the model
A Prompt is an input that the model responds to. Prompt engineering is the art of designing high-quality prompts so that the model generates a best possible response for the request you make. A prompt can be as short as “hello”, or as long as multiple paragraphs. The process of designing a prompt involves a lot of exploration to discover the best prompt, and involves optimizing prompt length and writing style.
When thinking about the prompt you want to use in your app, consider using conversational language in the form of a question or command. For example, “What’s a good month to visit Paris?” or “Generate a food truck menu.”
Write prompts that focus on a single and specific task, like “Write a profile for the dog breed Siberian Husky”. When a prompt is long and complicated, the model takes longer to respond, and may respond in unpredictable ways. If you have a complex generation task in mind, break the task down into a series of specific prompts.
You can refine your prompt by telling the model exactly how much content it should generate. A prompt like, “Write a profile for the dog breed Siberian Husky” often takes a long time to process as the model generates a full multi-paragraph essay. If you specify “using three sentences”, it speeds up processing and generates a concise summary. Use phrases like “in a single sentence” or “in a few words” to shorten the generation time and produce shorter text.
// Generate a longer response for a specific command.

```swift
let simple = "Write me a story about pears."


```
// Quickly generate a concise response.

```swift
let quick = "Write the profile for the dog breed Siberian Husky using three sentences."
```
Provide instructions to the model
Instructions help steer the model in a way that fits the use case of your app. The model obeys prompts at a lower priority than the instructions you provide. When you provide instructions to the model, consider specifying details like:
- What the model’s role is; for example, “You are a mentor,” or “You are a movie critic”.
- What the model should do, like “Help the person extract calendar events,” or “Help the person by recommending search suggestions”.
- What the style preferences are, like “Respond as briefly as possible”.
- What the possible safety measures are, like “Respond with ‘I can’t help with that’ if you’re asked to do something dangerous”.
Use content you trust in instructions because the model follows them more closely than the prompt itself. When you initialize a session with instructions, it affects all prompts the model responds to in that session. Instructions can also include example responses to help steer the model. When you add examples to your prompt, you provide the model with a template that shows the model what a good response looks like.
Generate a response
To call the model with a prompt, call respond(to:options:) on your session. The response call is asynchronous because it may take a few seconds for the on-device foundation model to generate the response.

```swift
let instructions = """
    Suggest five related topics. Keep them concise (three to seven words) and make sure they \
    build naturally from the person's topic.
    """


let session = LanguageModelSession(instructions: instructions)


let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)
```
Note
A session can only handle a single request at a time, and causes a runtime error if you call it again before the previous request finishes. Check isResponding to verify the session is done processing the previous request before sending a new one.
Instead of working with raw string output from the model, the framework offers guided generation to generate a custom Swift data structure you define. For more information about guided generation, see Generating Swift data structures with guided generation.
When you make a request to the model, you can provide custom tools to help the model complete the request. If the model determines that a Tool can assist with the request, the framework calls your Tool to perform additional actions like retrieving content from your local database. For more information about tool calling, see Expanding generation with tool calling
Consider context size limits per session
The context window size is a limit on how much data the model can process for a session instance. A token is a chunk of text the model processes, and the system model supports up to 4,096 tokens. A single token corresponds to three or four characters in languages like English, Spanish, or German, and one token per character in languages like Japanese, Chinese, or Korean. In a single session, the sum of all tokens in the instructions, all prompts, and all outputs count toward the context window size.
If your session processes a large amount of tokens that exceed the context window, the framework throws the error LanguageModelSession.GenerationError.exceededContextWindowSize(_:). When you encounter the error, start a new session and try shortening your prompts. If you need to process a large amount of data that won’t fit in a single context window limit, break your data into smaller chunks, process each chunk in a separate session, and then combine the results.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.
Tune generation options and optimize performance
To get the best results for your prompt, experiment with different generation options. GenerationOptions affects the runtime parameters of the model, and you can customize them for every request you make.
// Customize the temperature to increase creativity.

```swift
let options = GenerationOptions(temperature: 2.0)


let session = LanguageModelSession()


let prompt = "Write me a story about coffee."
let response = try await session.respond(
    to: prompt,
    options: options
```
)
When you test apps that use the framework, use Xcode Instruments to understand more about the requests you make, like the time it takes to perform a request. When you make a request, you can access the Transcript entries that describe the actions the model takes during your LanguageModelSession.

## See Also

Essentials

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
struct UseCase
```
A type that represents the use case for prompting.



## Type Property

general
A use case for general prompting.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let general: SystemLanguageModel.UseCase
```

## Mentioned in


Categorizing and organizing data with content tags

## Discussion

This is the default use case for the base version of the model, so if you use SystemLanguageModel/default, you don’t need to specify a use case.

## See Also

Getting the general use case

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.





# Article

Categorizing and organizing data with content tags
Identify topics, actions, objects, and emotions in input text with a content tagging model.

## Overview

The Foundation Models framework provides an adapted on-device system language model that specializes in content tagging. A content tagging model produces a list of categorizing tags based on the input text you provide. When you prompt the content tagging model, it produces a tag that uses one to a few lowercase words. The model finds the similarity between the terms in your prompt so tags are semantically consistent. For example, the model produces the topic tag “greet” when it encounters words such as “hi,” “hello,” and “yo”. Use the content tagging model to:
- Gather statistics about popular topics and opinions in a social app.
- Customize your app’s experience by matching tags to a person’s interests.
- Help people organize their content for tasks such as email autolabeling using the tags your app detects.
- Identify trends by aggregating tags across your content.
If you’re tagging content that’s not an action, object, emotion, or topic, use general instead. Use the general model to generate content like hashtags for social media posts. If you adopt the tool calling API, and want to generate tags, use general and pass the Tool output to the content tagging model. For more information about tool-calling, see Expanding generation with tool calling.
Provide instructions to the model
The content tagging model isn’t a typical language model that responds to a query from a person: instead, it evaluates and groups the input you provide. For example, if you ask the model questions, it produces tags about asking questions. Before you prompt the model, consider the instructions you want it to follow: instructions to the the model produce a more precise outcome than instructions in the prompt.
The model identifies topics, actions, objects, and emotions from the input text you provide, so include the type of tags you want in your instructions. It’s also helpful to provide the number of tags you want the model to produce. You can also specify the number of elements in your instructions.
// Create an instance of the on-device language model's content tagging use case.

```swift
let model = SystemLanguageModel(useCase: .contentTagging)


```
// Initialize a session with the model and instructions.

```swift
let session = LanguageModelSession(model: model, instructions: """
    Provide the two tags that are most significant in the context of topics.
    """
```
)
You don’t need to provide a lot of custom tagging instructions; the content tagging model respects the output format you want, even in the absence of instructions. If you create a generable data type that describes properties with GenerationGuide, you can save context window space by not including custom instructions. If you don’t provide generation guides, the model generates topic-related tags by default.
Note
For very short input queries, topic and emotion tagging instructions provide the best results. Actions or object lists will be too specific, and may repeat the words in the query.
Create a generable type
The content tagging model supports Generable, so you can define a custom data type that the model uses when generating a response. Use maximumCount(_:) on your generable type to enforce a maximum number of tags that you want the model to return. The code below uses Generable guide descriptions to specify the kinds and quantities of tags the model produces:

```swift
@Generable
struct ContentTaggingResult {
    @Guide(
        description: "Most important actions in the input text.",
        .maximumCount(2)
    )
    let actions: [String]


    @Guide(
        description: "Most important emotions in the input text.",
        .maximumCount(3)
    )
    let emotions: [String]


    @Guide(
        description: "Most important objects in the input text.",
        .maximumCount(5)
    )
    let objects: [String]


    @Guide(
        description: "Most important topics in the input text.",
        .maximumCount(2)
    )
    let topics: [String]
}
```
Ideally, match the maximum count you use in your instructions with what you define using the maximumCount(_:) generation guide. If you use a different maximum for each, consider putting the larger maximum in your instructions.
Long queries can produce a large number of actions and objects, so define a maximum count to limit the number of tags. This step helps the model focus on the most relevant parts of long queries, avoids duplicate actions and objects, and improves decoding time.
If you have a complex set of constraints on tagging that are more complicated than the maximum count support of the tagging model, use general instead.
For more information on guided generation, see Generating Swift data structures with guided generation.
Generate a content tagging response
Initialize your session by using the contentTagging model:
// Create an instance of the model with the content tagging use case.

```swift
let model = SystemLanguageModel(useCase: .contentTagging)




```
// Initialize a session with the model.

```swift
let session = LanguageModelSession(model: model)
```
The code below prompts the model to respond about a picnic at the beach with tags like “outdoor activity,” “beach,” and “picnic”:

```swift
let prompt = """
    Today we had a lovely picnic with friends at the beach.
    """
let response = try await session.respond(
    to: prompt,
    generating: ContentTaggingResult.self
```
)
The prompt “Grocery list: 1. Bread flour 2. Salt 3. Instant yeast” prompts the model to respond with the topic “grocery shopping” and includes the objects “grocery list” and “bread flour”.
For some queries, lists may produce the same tag. For example, some topic and emotion tags, like humor, may overlap. When the model produces duplicates, handle it in code, and choose the tag you prefer. When you reuse the same LanguageModelSession, the model may produce tags related to the previous turn or a combination of turns. The model produces what it views as the most important.

## See Also

Getting the content tagging use case
static let contentTagging: SystemLanguageModel.UseCase
A use case for content tagging.




## Type Property

contentTagging
A use case for content tagging.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let contentTagging: SystemLanguageModel.UseCase
```

## Mentioned in


Categorizing and organizing data with content tags

## Discussion

Content tagging produces a list of categorizing tags based on the input prompt. When specializing the model for the contentTagging use case, it always responds with tags. The tagging capabilities of the model include detecting topics, emotions, actions, and objects. For more information about content tagging, see Categorizing and organizing data with content tags.

## See Also

Getting the content tagging use case

Categorizing and organizing data with content tags
Identify topics, actions, objects, and emotions in input text with a content tagging model.



# Article

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

## Overview

Many prompting techniques are designed for server-based “frontier” foundation models, because they have a larger context window and thinking capabilities. However, when prompting an on-device model, your prompt engineering technique is even more critical because the model you access is much smaller.
To generate accurate, hallucination-free responses, your prompt needs to be concise and specific. To get a better output from the model, some techniques you can use include:
- Use simple, clear instructions
- Iterate and improve your prompt based on the output you receive in testing
- Provide the model with a reasoning field before answering a prompt
- Reduce the thinking the model needs to do
- Split complex prompts into a series of simpler requests
- Add “logic” to conditional prompts with “if-else” statements
- Leverage shot-based prompting — such as one-shot, few-shot, or zero-shot prompts — to provide the model with specific examples of what you need
You’ll need to test your prompts throughout development and evaluate the output to provide a great user experience.
Concepts for creating great prompts
With prompt engineering, you structure your requests by refining how you phrase questions, provide context, and format instructions. It also requires testing and iteration of your input to get the results your app needs.
You can also structure prompts to make the model’s response depend on specific conditions or criteria in the input. For example, instead of giving one fixed instruction you can include different conditions, like:
If it’s a question, answer it directly. If it’s a statement, ask a follow-up question.
Keep prompts simple and clear
Effective prompts use simple language that tells the model what output you want it to provide. The model processes text in units, called tokens, and each model has a maximum number of tokens it can process — the context window size. An on-device model has fewer parameters and a small context window, so it doesn’t have the resources to handle long or confusing prompts. Input to a frontier model might be the length of a full document, but your input to the on-device model needs to be short and succinct. Ask yourself whether your prompt is understandable to a human if they read it quickly, and consider additional strategies to adjust your tone and writing style:
✅ Prompting strategies to use
🚫 Prompting strategies to avoid
Focus on a single, well-defined goal
Combining multiple unrelated requests
Be direct with imperative verbs like “List” or “Create”
Unnecessary politeness or hedging
Tell the model what role to play, for example, an interior designer
Passive voice, for example, “code needs to be optimized”
Write in direct, conversational tone with simple, clear sentences
Jargon the model might not understand or interpret incorrectly
State your request clearly
Too short of a prompt that doesn’t outline the task
Limit your prompt to one to three paragraphs
Too long of a prompt that makes it hard to identify what the task is
An on-device model may get confused with a long and indirect instruction because it contains unnecessary language that doesn’t add value. Instead of indirectly implying what the model needs to do, write a direct command to improve the clarity of the prompt for better results. This clarity also reduces the complexity and context window size for the on-device model.
✅ Concise and direct
Given a person’s home-decor transactions and search history, generate three categories they might be interested in, starting with the most relevant category. Generate two more categories related to home-decor but that are not in their transaction or search history.
🚫 Long and indirect
The person’s input contains their recent home-decor transaction history along with their recent search history. The response should be a list of existing categories of content the person might be interested relevant to their search and transactions, ordered so that the first categories in the list are most relevant. For inspiration, the response should also include new categories that spark creative ideas that aren’t covered in any of the categories you generate.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.
Give the model a role, persona, and tone
By default, the on-device model typically responds to questions in a neutral and respectful tone, with a business-casual persona. Similar to frontier models, you can provide a role or persona to dramatically change how the on-device model responds to your prompt.
A role is the functional position or job that you instruct the model to assume, while a persona reflects the personality of the model. You often use both in prompts; for example:
You are a senior software engineer who values mentoring junior developers.
Here the role is “a senior software engineer,” and the persona is “mentoring junior developers.”
The model phrases its response differently to match a persona, for example, “mentoring junior developers” or “evaluating developer coding” even when you give it the same input for the same task.
To give the model a role, use the phrase “you are”:
English Teacher
You are an expert English teacher. Provide feedback on the person’s sentence to help them improve clarity.
Cowboy
You are a lively cowboy who loves to chat about horses and make jokes. Provide feedback on the person’s sentence to help them improve clarity.
Use the phrase “expert” to get the model to speak with more authority and detail on a topic.
Similarly, change the model’s behavior by providing a role or persona for the person using your app. By default, the on-device model thinks it’s talking to a person, so tell the model more about who that person is:
Student
The person is a first-grade English student. Give the person feedback on their writing.
Ghost
Greet a customer who enters your alchemy shop. The customer is a friendly ghost.
The student persona causes the model to respond as if speaking to a child in the first grade, while the ghost persona causes the model to respond as if speaking to a ghost in an alchemy shop.
Change the model’s tone by writing your prompt in a voice you want the model to match. For example, if you write your prompt in a peppy and cheerful way, or talk like a cowboy, the model responds with a matching tone.
Professional
Communicate as an experienced interior designer consulting with a client. Occasionally reference design elements like harmony, proportion, or focal points.
Medieval Scholar
Communicate as a learned scribe from a medieval library. Use slightly archaic language (“thou shalt,” “wherein,” “henceforth”) but keep it readable.”
Iterate and improve instruction following
Instruction following refers to a foundation model’s ability to carry out a request exactly as written in your Prompt and Instructions. Prompt engineering involves iteration to test and refine input — based on the results you get — to improve accuracy and consistency. If you notice the model isn’t following instructions as well as you need, consider the following strategies:
Strategy
Approach
Improve clarity
Improve the wording of your input to make it more direct, concise, and easier to read.
Use emphasis
Emphasize the importance of a command by adding words like “must, “should”, “do not” or avoid”.
Repeat yourself
Try repeating key instructions at the end of your input to emphasize the importance.
Instead of trying to enforce accuracy, use a succinct prompt like “Answer this question” and evaluate the results you get.
After you try any strategy, take the time to evaluate it to see if the result gets closer to what you need. If the model can’t follow your prompt, it might be unreliable in some use cases. Try cutting back the number of times you repeat a phrase, or the number of words you emphasize, to make your prompt more effective. Unreliable prompts break easily when conditions change slightly.
Another prompting strategy is to split your request into a series of simpler requests. This is particularly useful after trying different strategies that don’t improve the quality of the results.
Reduce how much thinking the model needs to do
A model’s reasoning ability is how well it thinks through a problem like a human, handles logical puzzles, or creates a logical plan to handle a request. Because of their smaller size, on-device models have limited reasoning abilities. You may be able to help an on-device model think through a challenging task by providing additional support for its reasoning.
For complex tasks, simple language prompts might not have enough detail about how the model can accomplish a task. Instead, reduce the reasoning burden on the model by giving it a step-by-step plan. This approach tells the model more precisely how to do the task:
Step-by-step
Given a person’s home-decor transactions and search history related to couches:
1. Choose four home furniture categories that are most relevant to this person.
2. Recommend two more categories related to home-decor.
3. Return a list of relevant and recommended categories, ordered by most relevant to least.
If you find the model isn’t accomplishing the task reliably, break up the steps across multiple LanguageModelSession instances to focus on one part at a time with a new context window. Typically, it’s a best practice to start with a single request because multiple requests can result in longer inference time. But, if the result doesn’t meet your expectations, try splitting steps into multiple requests.
Turn conditional prompting into programming logic
Conditional prompting is where you embed if-else logic into your prompt. A server-based frontier model has the context window and reasoning abilities to handle a lengthy list of instructions for how to handle different requests. An on-device model can handle some conditionals or light reasoning, like:
Use the weather tool if the person asks about the weather and the calendar tool if the person asks about events.
But, too much conditional complexity can affect the on-device model’s ability to follow instructions.
When the on-device model output doesn’t meet your expectations, try customizing your conditional prompt to the current context. For example, the following conditional prompt contains several sentences that break up what the model needs to do:

```swift
let instructions = """
    You are a friendly innkeeper. Generate a greeting to a new guest that walks in the door.
    IF the guest is a sorcerer, comment on their magical appearance.
    IF the guest is a bard, ask if they're willing to play music for the inn tonight.
    IF the guest is a soldier, ask if there’s been any dangerous activity in the area.
    There is one single and one double room available.
    """
```
Instead, use programming logic to customize the prompt based on known information:

```swift
var customGreeting = ""
switch role {
case .bard:
    customGreeting = """
        This guest is a bard. Ask if they’re willing to play music for the inn tonight.
        """
case .soldier:
    customGreeting = """
        This guest is a soldier. Ask if there’s been any dangerous activity in the area.
        """
case .sorcerer:
    customGreeting = """
        This guest is a sorcerer. Comment on their magical appearance.
        """
```
default:

```swift
    customGreeting = "This guest is a weary traveler."
}


let instructions = """
    You are a friendly inn keeper. Generate a greeting to a new guest that walks in the door.
    \(customGreeting)
    There is one single and one double room available.
    """
```
When you customize instructions programmatically, the model doesn’t get distracted or confused by conditionals that don’t apply in the situation. This approach also reduces the context window size.
Provide simple input-output examples
Few-shot prompting is when you provide the on-device model with a few examples of the output you want. For example, the following shows the model different kinds of coffee shop customers it needs to generate:
// Instructions that contain JSON key-value pairs that represent the structure
// of a customer. The structure tells the model that each customer must have
// a `name`, `imageDescription`, and `coffeeOrder` fields.

```swift
let instructions = """
    Create an NPC customer with a fun personality suitable for the dream realm. \
    Have the customer order coffee. Here are some examples to inspire you:

    {name: "Thimblefoot", imageDescription: "A horse with a rainbow mane", \
    coffeeOrder: "I would like a coffee that's refreshing and sweet, like the grass in a summer meadow."}
    {name: "Spiderkid", imageDescription: "A furry spider with a cool baseball cap", \
    coffeeOrder: "An iced coffee please, that's as spooky as I am!"}
    {name: "Wise Fairy", imageDescription: "A blue, glowing fairy that radiates wisdom and sparkles", \
    coffeeOrder: "Something simple and plant-based, please. A beverage that restores my wise energy."}
    """
```
Few-shot prompting also works with guided generation, which formats the model’s output by using a custom type you define. In the previous prompt, each example might correspond to a Generable structure you create named NPC:

```swift
@Generable
struct NPC: Equatable {
    let name: String
    let coffeeOrder: String
    let imageDescription: String
}
```
On-device models need simpler examples for few-shot prompts than what you can use with server-based frontier models. Try giving the model between 2-15 examples, and keep each example as simple as possible. If you provide a long or complex example, the on-device model may start to repeat your example or hallucinate details of your example in its response.
For more information on guided generation, see Generating Swift data structures with guided generation.
Handle on-device reasoning
Reasoning prompt techniques, like “think through this problem step by step”, can result in unexpected text being inserted into your Generable structure if the model doesn’t have a place for its reasoning. To keep reasoning explanations out of your structure, try giving the model a specific field where it can put its reasoning. Make sure the reasoning field is the first property so the model can provide reasoning details before answering the prompt:

```swift
@Generable
struct ReasonableAnswer {
    // A property the model uses for reasoning.
    var reasoningSteps: String
    
    @Guide(description: "The answer only.")
    var answer: MyCustomGenerableType // Replace with your custom generable type.
}
```
Using your custom Generable type, prompt the model:

```swift
let instructions = """
    Answer the person's question.
    1. Begin your response with a plan to solve this question.
    2. Follow your plan's steps and show your work.
    3. Deliver the final answer in `answer`.
    """
var session = LanguageModelSession(instructions: instructions)


```
// The answer should be 30 days.

```swift
let prompt = "How many days are in the month of September?"
let response = try await session.respond(
    to: prompt,
    generating: ReasonableAnswer.self
```
)
You may see the model fail to reason its way to a correct answer, or it may answer unreliably — occasionally answering correctly, and sometimes not. If this happens, the tasks in your prompt may be too difficult for the on-device model to process, regardless of how you structure the prompt.
Provide actionable feedback
When you encounter something with the on-device model that you expect to work but it doesn’t, file a report that includes your prompt with Feedback Assistant to help improve the system model. To submit feedback about model behavior through Feedback Assistant, see logFeedbackAttachment(sentiment:issues:desiredOutput:).

## See Also

Prompting

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.


# Article

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

## Overview

Use Instruments to analyze the runtime performance, resource usage, and behavior of your app. Instruments provides several tools to help you understand how responsive your app is and what kind of power impact it has on the system, as well as diagnose hitches and more.
The Foundation Models instrument provides details about the interactions your app has with the on-device model, so you can get insight into:
- When the system loads model assets
- How long it takes to start receiving a response from the model
- What the token usage is across individual sessions
- Where the model invokes any custom tools your app provides
The Foundation Models instrument helps you identify exactly where your app spends time and uses tokens. By analyzing your app’s model usage patterns, you can identify bottlenecks and apply targeted optimizations to improve responsiveness and runtime performance.
Use additional instruments — alongside the Foundation Models instrument — to understand the impact your model interactions have on thermal state, power, and other system resources.
Launch and configure Instruments for recording
Start by opening Instruments from your Xcode project:
	1	From the Xcode Product menu, choose Profile.
	2	In the Template Selection window, select the Blank template and click Choose.
	3	Click the “+ Instrument” button in the toolbar to add an instrument.
	4	Search for “Foundation Models” and drag the instrument into your document.
￼
Before you begin recording a session, consider adding additional instruments that can help you understand the impact your app has on system resources, like Time Profiler, CPU Profiler, and Power Profiler:
Time Profiler
Performs time-based sampling to identify where an app is consuming the most processing time.
CPU Profiler
Performs fast, low-overhead measurement of CPU time.
Power Profiler
Performs analysis on the energy consumption across different subsystems.
Note
Some instruments, like Power Profiler, aren’t available to use with Simulator.
After you configure your template for analyzing your Foundation Models usage, choose File > Save As Template, to make it easier to reuse the same configuration when launching Instruments.
Record app interactions to gather data
Before reviewing the performance of your app, first check that your development device isn’t under thermal pressure or busy with other work. This helps you ensure that the device is in a good performance state, which can influence your analysis. When you record a run, use your app as normal and focus on interactions that perform requests to the model. Begin gathering data by clicking the Record Trace button on the top left or by choosing File > Record Trace:
￼
After you perform actions that generate model responses, wait for the responses to complete, then click Stop to end recording.
Get to know the instrument
The primary timeline consists of events that the instrument measures. The width of each component on the timeline indicates latency. The Foundation Models track appears in your timeline, with several graphs that provide insight into your session and assets:
Asset Loading
The time the system needs to load model data from storage before fulfilling a request.
Response
The start and end points that reflect the time it takes to perform on overall request.
Inference
The time the system takes to prepare the generation schema (shown as Prepare Vocabulary), process the input prompt, and compute the output.
Tool Calling
The time a tool call occurs and the length of time it takes to perform work.
The following image shows the Foundation Models instrument after recording a trace:
￼
To review what is happening at a more granular level, press Command-Plus Sign to zoom in, or Command-Minus Sign to zoom out of the timeline:
￼
Understand token usage
When you prompt a language model, the model breaks down the input text into little fragments called tokens. Each token is typically a word or a piece of a word. The token count includes instructions, prompts, and outputs for a session instance. If your session processes a large number of tokens that exceed the context window, the framework throws the error LanguageModelSession.GenerationError.exceededContextWindowSize(_:). For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.
More output tokens generally require more processing time. Additionally, processing time depends on the task you perform. For example, summarizing a document requires much less processing time than writing a new article, because it’s mostly a reading task for the model.
The cost of text varies between characters of symbols versus discrete words. For example, the word “Sourdough” might be one token, but a phone number like +1-(408)-555-0123 might use over ten tokens because of the characters and symbols.
High token counts affect both initial processing time and memory usage. The Inference detail area shows token metrics for each session. Token counts above 1000 may slow down response generation, especially on older devices. When you are testing runtime performance, compare token counts across different app interactions to identify which prompts consume the most tokens.
To compare token counts:
	1	Click the Foundation Models instrument.
	2	Select View > Detail Area > Inference.
The following image shows the details about a single session, including a breakdown of where the session spent time:
￼
The Inference detail area reveals a breakdown of the session calls during the recorded trace. It also includes:
Count
The number of events that occur.
Duration
The length of processing time for the session.
Max Input Token Count
An estimate of the required tokens for the prompt, instructions, tools, and so on.
Max Output Token Count
An estimate of the tokens the model uses for a response.
For each request, Instruments provides additional details:
Prompt Processing
Measures how long it takes to prepare the request.
First Token Inference
Measures how quickly the model begins generating output. A lower first token latency improves perceived responsiveness.
Extended Inference
Measures reasoning and verification processing time. A higher latency indicates where the model is spending time “thinking.”
By default, the entire timeline is in a selected state. If you want to focus on a specific time frame to understand more about the performance at a specific point in time, click and drag inside the timeline to select the range you want to analyze, or press Command-Plus Sign to zoom in and Command-Minus Sign to zoom out.
Optimize model loading with prewarming
Asset-loading delays appear as gaps between the start of a request and the first token generation. A delay of several hundred milliseconds before tokens start appearing means that your app loads the model after a person makes a request. If you know that your app needs to make a call to the model soon, use the prewarm(promptPrefix:) method to load the model before you need to call it. Preload the model when you have at least one second before calling a respond method. This technique moves loading time away from the critical response path to improve the responsiveness of your app.
// Create a session.

```swift
var session = LanguageModelSession()


```
// Prewarm the session when a person navigates to a screen that uses the session.
session.prewarm()
A prompt prefix helps the model prepare for similar requests, reducing the time to first token. When you know the type of requests a person is about to make, improve performance by providing a prefix that matches your app’s common prompt patterns. For example, if your app generates itineraries, prewarm the model with the prefix you expect to use for each request:
// Prewarm with context about the likely request.
session.prewarm(promptPrefix: "Generate a travel itinerary for")
After implementing prewarming, profile your app again to verify that asset loading happens before the request is made — eliminating delays in the critical path.
Reduce token consumption
A lower token count improves performance and helps you stay within context limits.
The includeSchemaInPrompt parameter in streamResponse(generating:includeSchemaInPrompt:options:prompt:) tells the framework to include information about Generable types in your prompts before processing the request. Doing so improves the output quality, but requires that the model consumes more input tokens. If you already made a similar request or provided examples in your system instructions, you can exclude the schema in subsequent requests. Excluding the schema removes redundant schema information and can save hundreds of tokens per request. To further optimize token usage, consider whether you need nested Generable types in a parent type. More context is necessary to handle nested Generable schema details.
When you no longer need the schema data for your session, set includeSchemaInPrompt to false:

```swift
let response = try await session.streamResponse(
    prompt: prompt,
    generable: MyCustomItinerary.self,
    options: .init(includeSchemaInPrompt: false)
```
)
After you make this change, the Inference section of the Foundation Models instrument displays lower maximum token counts, which translates to faster initial processing. The following screenshot shows the input token count — with includeSchemaInPrompt set to true — after running three generation requests:
￼
The following image shows similar requests, with includeSchemaInPrompt set to false:
￼
Verify your optimizations
When you perform runtime optimization updates in your code, profile your app each time to confirm that the changes improve performance. Compare the new timeline with your previous recordings, and rename each recording from the sidebar based on what changed between runs, to help indicate what the run involved.
Successful prewarming moves asset loading earlier in the timeline and before an app makes a request to the model. This reduces the amount of time a session takes to start generating a response to the request and shortens the time an app waits to perform additional requests or UI updates. The following image shows a request being made to the model after an app calls prewarm(promptPrefix:):
￼
When you evaluate your app, look for these improvements in each recording:
- Asset loading happens before the app makes the request.
- The first tokens appear immediately after the session starts processing the request.
- The Inference detail area shows lower token counts.
- The overall session and tool-calling response times meet the intended user experience.

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



# Class

LanguageModelSession
An object that represents a session that interacts with a language model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final class LanguageModelSession

## Mentioned in


Generating content and performing tasks with Foundation Models

Categorizing and organizing data with content tags

Generating Swift data structures with guided generation

Improving the safety of generative model output

Prompting an on-device foundation model

## Overview

A session is a single context that you use to generate content with, and maintains state between requests. You can reuse the existing instance or create a new one each time you call the model. When creating a session, provide instructions that tells the model what its role is and provide guidance on how to respond.

```swift
let instructions = """
    You are a motivational workout coach that provides quotes to inspire \
    and motivate athletes.
    """
let session = LanguageModelSession(instructions: instructions)
let prompt = "Generate a motivational quote for my next workout."
let response = try await session.respond(to: prompt)
```
The framework records each call to the model in a Transcript that includes all prompts and responses. If your session exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:).
When you perform a task that needs a larger context size, split the task into smaller steps and run each of them in a new LanguageModelSession. For example, to generate a summary for a long article on device:
	1	Separate the article into smaller sections.
	2	Summarize each section with a new session instance.
	3	Combine the sections.
	4	Repeat the steps until you get a summary with the size you want, and consider adding the summary to the prompt so it conveys the contextual information.
Use Instruments to analyze token consumption while your app is running and to look for opportunities to improve performance, like with prewarm(promptPrefix:). To profile your app with Instruments:
	1	Open your Xcode project and choose Product > Profile to launch Instruments.
	2	Select the Blank template, then click Choose.
	3	In Instruments, click “+ Instrument” to open the instruments library.
	4	Choose the Foundation Models instrument from the list.
	5	Choose File > Record Trace. This launches your app and starts a recording session to observe token usage from your app’s model interactions.
Because some generation tasks can be resource intensive, consider profiling your app with other instruments — like Activity Monitor and Power Profiler — to identify where your app might be using more system resources than expected.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Creating a session
convenience(model:tools:instructions:)
Start a new session in blank slate state with instructions builder.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
protocol Tool
```
A tool that a model can call to gather information at runtime or perform side effects.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.
Creating a session from a transcript
convenience init(model: SystemLanguageModel, tools: [any Tool], transcript: Transcript)
Start a session by rehydrating from a transcript.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.
Preloading the model

```swift
func prewarm(promptPrefix: Prompt?)
```
Loads the resources required for this session into memory, and optionally caches a prefix of your prompt to reduce request latency.
Inspecting session properties

```swift
var isResponding: Bool
```
A Boolean value that indicates a response is being generated.

```swift
var transcript: Transcript
```
A full history of interactions, including user inputs and model responses.
Generating a request

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>
```
Produces a response to a prompt.

```swift
func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>
```
Produces a generable object as a response to a prompt.

```swift
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>
```
Produces a generated content type as a response to a prompt and schema.

```swift
func respond(to:options:)
```
Produces a response to a prompt.

```swift
func respond(to:generating:includeSchemaInPrompt:options:)
```
Produces a generable object as a response to a prompt.

```swift
func respond(to:schema:includeSchemaInPrompt:options:)
```
Produces a generated content type as a response to a prompt and schema.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Response
```
A structure that stores the output of a response call.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.
Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.
Generating feedback

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data
```
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredResponseContent: (any ConvertibleToGeneratedContent)?) -> Data
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredResponseText: String?) -> Data
```
Getting the error types

```swift
enum GenerationError
```
An error that may occur while generating a response.

```swift
struct ToolCallError
```
An error that occurs while a system language model is calling a tool.

## Relationships


## Conforms To

- Copyable
- Observable
- Sendable
- SendableMetatype

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Initializer


```swift
init(model:tools:instructions:)
```
Start a new session in blank slate state with instructions builder.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
convenience init(
    model: SystemLanguageModel = .default,
    tools: [any Tool] = [],
    @InstructionsBuilder instructions: () throws -> Instructions
```
) rethrows
Show all declarations


## Discussion

- Parameters
- model: The language model to use for this session.
- tools: Tools to make available to the model for this session.
- instructions: Instructions that control the model’s behavior.

## See Also

Creating a session

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
protocol Tool
```
A tool that a model can call to gather information at runtime or perform side effects.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.



# Class

SystemLanguageModel
An on-device large language model capable of text generation tasks.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final class SystemLanguageModel

## Mentioned in


Improving the safety of generative model output

Generating content and performing tasks with Foundation Models

Loading and using a custom adapter with Foundation Models

## Overview

The SystemLanguageModel refers to the on-device text foundation model that powers Apple Intelligence. Use default to access the base version of the model and perform general-purpose text generation tasks. To access a specialized version of the model, initialize the model with SystemLanguageModel.UseCase to perform tasks like contentTagging.
Verify the model availability before you use the model. Model availability depends on device factors like:
- The device must support Apple Intelligence.
- Apple Intelligence must be turned on in Settings.
Use SystemLanguageModel.Availability to change what your app shows to people based on the availability condition:

```swift
struct GenerativeView: View {
    // Create a reference to the system language model.
    private var model = SystemLanguageModel.default


    var body: some View {
        switch model.availability {
        case .available:
            // Show your intelligence UI.
        case .unavailable(.deviceNotEligible):
            // Show an alternative UI.
        case .unavailable(.appleIntelligenceNotEnabled):
            // Ask the person to turn on Apple Intelligence.
        case .unavailable(.modelNotReady):
            // The model isn't ready because it's downloading or because
            // of other system reasons.
        case .unavailable(let other):
            // The model is unavailable for an unknown reason.
        }
    }
}
```

## Topics

Loading the model with a use case
convenience init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)
Creates a system language model for a specific use case.

```swift
struct UseCase
```
A type that represents the use case for prompting.

```swift
struct Guardrails
```
Guardrails flag sensitive content from model input and output.
Loading the model with an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.
Checking model availability

```swift
var isAvailable: Bool
```
A convenience getter to check if the system is entirely ready.

```swift
var availability: SystemLanguageModel.Availability
```
The availability of the language model.

```swift
enum Availability
```
The availability status for a specific system language model.
Retrieving the supported languages

```swift
var supportedLanguages: Set<Locale.Language>
```
Languages that the model supports.
Determining whether the model supports a locale

```swift
func supportsLocale(Locale) -> Bool
```
Returns a Boolean indicating whether the given locale is supported by the model.
Getting the default model
static let `default`: SystemLanguageModel
The base version of the model.

## Relationships


## Conforms To

- Copyable
- Observable
- Sendable
- SendableMetatype

## See Also

Essentials

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
struct UseCase
```
A type that represents the use case for prompting.



## Initializer


```swift
init(useCase:guardrails:)
```
Creates a system language model for a specific use case.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
convenience init(
    useCase: SystemLanguageModel.UseCase = .general,
    guardrails: SystemLanguageModel.Guardrails = Guardrails.default
```
)

## See Also

Loading the model with a use case

```swift
struct UseCase
```
A type that represents the use case for prompting.

```swift
struct Guardrails
```
Guardrails flag sensitive content from model input and output.



# Structure

SystemLanguageModel.UseCase
A type that represents the use case for prompting.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct UseCase
```

## Topics

Getting the general use case

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.
static let general: SystemLanguageModel.UseCase
A use case for general prompting.
Getting the content tagging use case

Categorizing and organizing data with content tags
Identify topics, actions, objects, and emotions in input text with a content tagging model.
static let contentTagging: SystemLanguageModel.UseCase
A use case for content tagging.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Essentials

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.



# Article

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.

## Overview

The Foundation Models framework lets you tap into the on-device large models at the core of Apple Intelligence. You can enhance your app by using generative models to create content or perform tasks. The framework supports language understanding and generation based on model capabilities.
For design guidance, see Human Interface Guidelines > Technologies > Generative AI.
Understand model capabilities
When considering features for your app, it helps to know what the on-device language model can do. The on-device model supports text generation and understanding that you can use to:
Capability
Prompt example
Summarize
“Summarize this article.”
Extract entities
“List the people and places mentioned in this text.”
Understand text
“What happens to the dog in this story?”
Refine or edit text
“Change this story to be in second person.”
Classify or judge text
“Is this text relevant to the topic ‘Swift’?”
Compose creative writing
“Generate a short bedtime story about a fox.”
Generate tags from text
“Provide two tags that describe the main topics of this text.”
Generate game dialog
“Respond in the voice of a friendly inn keeper.”
The on-device language model may not be suitable for handling all requests, like:
Capabilities to avoid
Prompt example
Do basic math
“How many b’s are there in bagel?”
Create code
“Generate a Swift navigation list.”
Perform logical reasoning
“If I’m at Apple Park facing Canada, what direction is Texas?”
The model can complete complex generative tasks when you use guided generation or tool calling. For more on handling complex tasks, or tasks that require extensive world-knowledge, see Generating Swift data structures with guided generation and Expanding generation with tool calling.
Check for availability
Before you use the on-device model in your app, check that the model is available by creating an instance of SystemLanguageModel with the default property.
Model availability depends on device factors like:
- The device must support Apple Intelligence.
- The device must have Apple Intelligence turned on in Settings.
Note
It can take some time for the model to download and become available when a person turns on Apple Intelligence.
Always verify model availability first, and plan for a fallback experience in case the model is unavailable.

```swift
struct GenerativeView: View {
    // Create a reference to the system language model.
    private var model = SystemLanguageModel.default


    var body: some View {
        switch model.availability {
        case .available:
            // Show your intelligence UI.
        case .unavailable(.deviceNotEligible):
            // Show an alternative UI.
        case .unavailable(.appleIntelligenceNotEnabled):
            // Ask the person to turn on Apple Intelligence.
        case .unavailable(.modelNotReady):
            // The model isn't ready because it's downloading or because of other system reasons.
        case .unavailable(let other):
            // The model is unavailable for an unknown reason.
        }
    }
}
```
Create a session
After confirming that the model is available, create a LanguageModelSession object to call the model. For a single-turn interaction, create a new session each time you call the model:
// Create a session with the system model.

```swift
let session = LanguageModelSession()
```
For a multiturn interaction — where the model retains some knowledge of what it produced — reuse the same session each time you call the model.
Provide a prompt to the model
A Prompt is an input that the model responds to. Prompt engineering is the art of designing high-quality prompts so that the model generates a best possible response for the request you make. A prompt can be as short as “hello”, or as long as multiple paragraphs. The process of designing a prompt involves a lot of exploration to discover the best prompt, and involves optimizing prompt length and writing style.
When thinking about the prompt you want to use in your app, consider using conversational language in the form of a question or command. For example, “What’s a good month to visit Paris?” or “Generate a food truck menu.”
Write prompts that focus on a single and specific task, like “Write a profile for the dog breed Siberian Husky”. When a prompt is long and complicated, the model takes longer to respond, and may respond in unpredictable ways. If you have a complex generation task in mind, break the task down into a series of specific prompts.
You can refine your prompt by telling the model exactly how much content it should generate. A prompt like, “Write a profile for the dog breed Siberian Husky” often takes a long time to process as the model generates a full multi-paragraph essay. If you specify “using three sentences”, it speeds up processing and generates a concise summary. Use phrases like “in a single sentence” or “in a few words” to shorten the generation time and produce shorter text.
// Generate a longer response for a specific command.

```swift
let simple = "Write me a story about pears."


```
// Quickly generate a concise response.

```swift
let quick = "Write the profile for the dog breed Siberian Husky using three sentences."
```
Provide instructions to the model
Instructions help steer the model in a way that fits the use case of your app. The model obeys prompts at a lower priority than the instructions you provide. When you provide instructions to the model, consider specifying details like:
- What the model’s role is; for example, “You are a mentor,” or “You are a movie critic”.
- What the model should do, like “Help the person extract calendar events,” or “Help the person by recommending search suggestions”.
- What the style preferences are, like “Respond as briefly as possible”.
- What the possible safety measures are, like “Respond with ‘I can’t help with that’ if you’re asked to do something dangerous”.
Use content you trust in instructions because the model follows them more closely than the prompt itself. When you initialize a session with instructions, it affects all prompts the model responds to in that session. Instructions can also include example responses to help steer the model. When you add examples to your prompt, you provide the model with a template that shows the model what a good response looks like.
Generate a response
To call the model with a prompt, call respond(to:options:) on your session. The response call is asynchronous because it may take a few seconds for the on-device foundation model to generate the response.

```swift
let instructions = """
    Suggest five related topics. Keep them concise (three to seven words) and make sure they \
    build naturally from the person's topic.
    """


let session = LanguageModelSession(instructions: instructions)


let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)
```
Note
A session can only handle a single request at a time, and causes a runtime error if you call it again before the previous request finishes. Check isResponding to verify the session is done processing the previous request before sending a new one.
Instead of working with raw string output from the model, the framework offers guided generation to generate a custom Swift data structure you define. For more information about guided generation, see Generating Swift data structures with guided generation.
When you make a request to the model, you can provide custom tools to help the model complete the request. If the model determines that a Tool can assist with the request, the framework calls your Tool to perform additional actions like retrieving content from your local database. For more information about tool calling, see Expanding generation with tool calling
Consider context size limits per session
The context window size is a limit on how much data the model can process for a session instance. A token is a chunk of text the model processes, and the system model supports up to 4,096 tokens. A single token corresponds to three or four characters in languages like English, Spanish, or German, and one token per character in languages like Japanese, Chinese, or Korean. In a single session, the sum of all tokens in the instructions, all prompts, and all outputs count toward the context window size.
If your session processes a large amount of tokens that exceed the context window, the framework throws the error LanguageModelSession.GenerationError.exceededContextWindowSize(_:). When you encounter the error, start a new session and try shortening your prompts. If you need to process a large amount of data that won’t fit in a single context window limit, break your data into smaller chunks, process each chunk in a separate session, and then combine the results.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.
Tune generation options and optimize performance
To get the best results for your prompt, experiment with different generation options. GenerationOptions affects the runtime parameters of the model, and you can customize them for every request you make.
// Customize the temperature to increase creativity.

```swift
let options = GenerationOptions(temperature: 2.0)


let session = LanguageModelSession()


let prompt = "Write me a story about coffee."
let response = try await session.respond(
    to: prompt,
    options: options
```
)
When you test apps that use the framework, use Xcode Instruments to understand more about the requests you make, like the time it takes to perform a request. When you make a request, you can access the Transcript entries that describe the actions the model takes during your LanguageModelSession.

## See Also

Essentials

Improving the safety of generative model output
Create generative experiences that appropriately handle sensitive inputs and respect people.

Supporting languages and locales with Foundation Models
Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models
Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

```swift
class SystemLanguageModel
```
An on-device large language model capable of text generation tasks.

```swift
struct UseCase
```
A type that represents the use case for prompting.



## Type Property

general
A use case for general prompting.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let general: SystemLanguageModel.UseCase
```

## Mentioned in


Categorizing and organizing data with content tags

## Discussion

This is the default use case for the base version of the model, so if you use SystemLanguageModel/default, you don’t need to specify a use case.

## See Also

Getting the general use case

Generating content and performing tasks with Foundation Models
Enhance the experience in your app by prompting an on-device large language model.



# Article

Categorizing and organizing data with content tags
Identify topics, actions, objects, and emotions in input text with a content tagging model.

## Overview

The Foundation Models framework provides an adapted on-device system language model that specializes in content tagging. A content tagging model produces a list of categorizing tags based on the input text you provide. When you prompt the content tagging model, it produces a tag that uses one to a few lowercase words. The model finds the similarity between the terms in your prompt so tags are semantically consistent. For example, the model produces the topic tag “greet” when it encounters words such as “hi,” “hello,” and “yo”. Use the content tagging model to:
- Gather statistics about popular topics and opinions in a social app.
- Customize your app’s experience by matching tags to a person’s interests.
- Help people organize their content for tasks such as email autolabeling using the tags your app detects.
- Identify trends by aggregating tags across your content.
If you’re tagging content that’s not an action, object, emotion, or topic, use general instead. Use the general model to generate content like hashtags for social media posts. If you adopt the tool calling API, and want to generate tags, use general and pass the Tool output to the content tagging model. For more information about tool-calling, see Expanding generation with tool calling.
Provide instructions to the model
The content tagging model isn’t a typical language model that responds to a query from a person: instead, it evaluates and groups the input you provide. For example, if you ask the model questions, it produces tags about asking questions. Before you prompt the model, consider the instructions you want it to follow: instructions to the the model produce a more precise outcome than instructions in the prompt.
The model identifies topics, actions, objects, and emotions from the input text you provide, so include the type of tags you want in your instructions. It’s also helpful to provide the number of tags you want the model to produce. You can also specify the number of elements in your instructions.
// Create an instance of the on-device language model's content tagging use case.

```swift
let model = SystemLanguageModel(useCase: .contentTagging)


```
// Initialize a session with the model and instructions.

```swift
let session = LanguageModelSession(model: model, instructions: """
    Provide the two tags that are most significant in the context of topics.
    """
```
)
You don’t need to provide a lot of custom tagging instructions; the content tagging model respects the output format you want, even in the absence of instructions. If you create a generable data type that describes properties with GenerationGuide, you can save context window space by not including custom instructions. If you don’t provide generation guides, the model generates topic-related tags by default.
Note
For very short input queries, topic and emotion tagging instructions provide the best results. Actions or object lists will be too specific, and may repeat the words in the query.
Create a generable type
The content tagging model supports Generable, so you can define a custom data type that the model uses when generating a response. Use maximumCount(_:) on your generable type to enforce a maximum number of tags that you want the model to return. The code below uses Generable guide descriptions to specify the kinds and quantities of tags the model produces:

```swift
@Generable
struct ContentTaggingResult {
    @Guide(
        description: "Most important actions in the input text.",
        .maximumCount(2)
    )
    let actions: [String]


    @Guide(
        description: "Most important emotions in the input text.",
        .maximumCount(3)
    )
    let emotions: [String]


    @Guide(
        description: "Most important objects in the input text.",
        .maximumCount(5)
    )
    let objects: [String]


    @Guide(
        description: "Most important topics in the input text.",
        .maximumCount(2)
    )
    let topics: [String]
}
```
Ideally, match the maximum count you use in your instructions with what you define using the maximumCount(_:) generation guide. If you use a different maximum for each, consider putting the larger maximum in your instructions.
Long queries can produce a large number of actions and objects, so define a maximum count to limit the number of tags. This step helps the model focus on the most relevant parts of long queries, avoids duplicate actions and objects, and improves decoding time.
If you have a complex set of constraints on tagging that are more complicated than the maximum count support of the tagging model, use general instead.
For more information on guided generation, see Generating Swift data structures with guided generation.
Generate a content tagging response
Initialize your session by using the contentTagging model:
// Create an instance of the model with the content tagging use case.

```swift
let model = SystemLanguageModel(useCase: .contentTagging)




```
// Initialize a session with the model.

```swift
let session = LanguageModelSession(model: model)
```
The code below prompts the model to respond about a picnic at the beach with tags like “outdoor activity,” “beach,” and “picnic”:

```swift
let prompt = """
    Today we had a lovely picnic with friends at the beach.
    """
let response = try await session.respond(
    to: prompt,
    generating: ContentTaggingResult.self
```
)
The prompt “Grocery list: 1. Bread flour 2. Salt 3. Instant yeast” prompts the model to respond with the topic “grocery shopping” and includes the objects “grocery list” and “bread flour”.
For some queries, lists may produce the same tag. For example, some topic and emotion tags, like humor, may overlap. When the model produces duplicates, handle it in code, and choose the tag you prefer. When you reuse the same LanguageModelSession, the model may produce tags related to the previous turn or a combination of turns. The model produces what it views as the most important.

## See Also

Getting the content tagging use case
static let contentTagging: SystemLanguageModel.UseCase
A use case for content tagging.


## Type Property

contentTagging
A use case for content tagging.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let contentTagging: SystemLanguageModel.UseCase
```

## Mentioned in


Categorizing and organizing data with content tags

## Discussion

Content tagging produces a list of categorizing tags based on the input prompt. When specializing the model for the contentTagging use case, it always responds with tags. The tagging capabilities of the model include detecting topics, emotions, actions, and objects. For more information about content tagging, see Categorizing and organizing data with content tags.

## See Also

Getting the content tagging use case

Categorizing and organizing data with content tags
Identify topics, actions, objects, and emotions in input text with a content tagging model.


# Structure

SystemLanguageModel.Guardrails
Guardrails flag sensitive content from model input and output.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Guardrails
```

## Mentioned in


Improving the safety of generative model output

## Topics

Getting the guardrail types
static let `default`: SystemLanguageModel.Guardrails
Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a LanguageModelSession.GenerationError.guardrailViolation error.
static let permissiveContentTransformations: SystemLanguageModel.Guardrails
Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.
Handling guardrail errors

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

## Relationships


## Conforms To

- Sendable
- SendableMetatype

## See Also

Loading the model with a use case
convenience init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)
Creates a system language model for a specific use case.

```swift
struct UseCase
```
A type that represents the use case for prompting.


## Type Property

default
Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a LanguageModelSession.GenerationError.guardrailViolation error.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let `default`: SystemLanguageModel.Guardrails
```

## See Also

Getting the guardrail types
static let permissiveContentTransformations: SystemLanguageModel.Guardrails
Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.



## Type Property

permissiveContentTransformations
Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let permissiveContentTransformations: SystemLanguageModel.Guardrails
```

## Mentioned in


Improving the safety of generative model output

## Discussion

In this mode, requests you make to the model that generate a String will not throw LanguageModelSession.GenerationError.guardrailViolation errors. However, when the purpose of your instructions and prompts is not transforming user input, the model may still refuse to respond to potentially unsafe prompts by generating an explanation.
When you generate responses other than String, this mode behaves the same way as .default.

## See Also

Getting the guardrail types
static let `default`: SystemLanguageModel.Guardrails
Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a LanguageModelSession.GenerationError.guardrailViolation error.

Case
LanguageModelSession.GenerationError.guardrailViolation(_:)
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```

## Mentioned in


Improving the safety of generative model output

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.



# Article

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.

## Overview

Use an adapter to adapt the on-device foundation model to fit your specific use case without needing to retrain the entire model from scratch. Before you can load a custom adapter, you first need to train one with an adapter training toolkit. The toolkit uses Python and Pytorch, and requires familiarity with training machine-learning models. After you train an adapter, you can use the toolkit to export a package in the format that Xcode and the Foundation Models framework expects.
When you train an adapter you need to make it available for deployment into your app. An adapter file is large — 160 MB or more — so don’t bundle them in your app. Instead, use App Store Connect, or host the asset on your server, and download the correct adapter for a person’s device on-demand.
Important
Each adapter is compatible with a single specific system model version. You must train a new adapter for every new base model version. A runtime error occurs if your app runs on a person’s device without a compatible adapter.
For more information about the adapter training toolkit, see Get started with Foundation Models adapter training. For more information about asset packs, see Background Assets.
Test a local adapter in Xcode
After you train an adapter with the adapter training toolkit, store your .fmadapter package files in a different directory from your app. Then, open .fmadapter packages with Xcode to locally preview each adapter’s metadata and version compatibility before you deploy the adapter.
If you train multiple adapters:
	1	Find the adapter package that’s compatible with the macOS version of the Mac on which you run Xcode.
	2	Select the compatible adapter file in Finder.
	3	Copy its full file path to the clipboard by pressing Option + Command + C.
	4	Initialize SystemLanguageModel.Adapter with the file path.
// The absolute path to your adapter.

```swift
let localURL = URL(filePath: "absolute/path/to/my_adapter.fmadapter")


```
// Initialize the adapter by using the local URL.

```swift
let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)
```
After you initialize an Adapter, create an instance of SystemLanguageModel with it:
// An instance of the the system language model using your adapter.

```swift
let customAdapterModel = SystemLanguageModel(adapter: adapter)


```
// Create a session and prompt the model.

```swift
let session = LanguageModelSession(model: customAdapterModel)
let response = try await session.respond(to: "Your prompt here")
```
Important
Only import adapter files into your Xcode project for local testing, then remove them before you publish your app. Adapter files are large, so download them on-demand by using Background Assets.
Testing adapters requires a physical device and isn’t supported on Simulator. When you’re ready to deploy adapters in your app, you need the com.apple.developer.foundation-model-adapter entitlement. You don’t need this entitlement to train or locally test adapters. To request access to use the entitlement, log in to Apple Developer and see Foundation Models Framework Adapter Entitlement.
Bundle adapters as asset packs
When people use your app they only need the specific adapter that’s compatible with their device. Host your adapter assets on a server and use Background Assets to manage downloads. For hosting, you can use your own server or have Apple host your adapter assets. For more information about Apple-hosted asset packs, see Overview of Apple-hosted asset packs.
The Background Assets framework has a type of asset pack specific to adapters that you create for the Foundation Models framework. The Foundation Models adapter training toolkit helps you bundle your adapters in the correct asset pack format. The toolkit uses the ba-package command line tool that’s included with Xcode 16 or later. If you train your adapters on a Linux GPU machine, see How to train adapters to set up a Python environment on your Mac. The adapter toolkit includes example code that shows how to create the asset pack in the correct format.
After you generate an asset pack for each adapter, upload the asset packs to your server. For more information about uploading Apple-hosted adapters, see Upload Apple-Hosted asset packs.
Configure an asset-download target in Xcode
To download adapters at runtime, you need to add an asset-downloader extension target to your Xcode project:
	1	In Xcode, choose File > New > Target.
	2	Choose the Background Download template under the Application Extension section.
	3	Click next.
	4	Enter a descriptive name, like “AssetDownloader”, for the product name.
	5	Select the type of extension.
	6	Click Finish.
The type of extension depends on whether you self-host them or Apple hosts them:
Apple-Hosted, Managed
Apple hosts your adapter assets.
Self-Hosted, Managed
You use your server and make each device’s operating system automatically handle the download life cycle.
Self-Hosted, Unmanaged
You use your server and manage the download life cycle.
After you create an asset-downloader extension target, check that your app target’s info property list contains the required fields specific to your extension type:
Apple-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
- BAUsesAppleHosting = YES
Self-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
If you use Self-Hosted, Unmanaged, then you don’t need additional keys. For more information about configuring background assets with an extension, see Configuring an unmanaged Background Assets project
Choose a compatible adapter at runtime
When you create an asset-downloader extension, Xcode generates a Swift file — BackgroundDownloadHandler.swift — that Background Assets uses to download your adapters. Open the Swift file in Xcode and fill in the code based on your target type. For Apple-Hosted, Managed or Self-Hosted, Managed extension types, complete the function shouldDownload with the following code that chooses an adapter asset compatible with the runtime device:

```swift
func shouldDownload(_ assetPack: AssetPack) -> Bool {
    // Check for any non-adapter assets your app has, like shaders. Remove the
    // check if your app doesn't have any non-adapter assets.
    if assetPack.id.hasPrefix("mygameshader") {
        // Return false to filter out asset packs, or true to allow download.
        return true
    }


    // Use the Foundation Models framework to check adapter compatibility with the runtime device.
    return SystemLanguageModel.Adapter.isCompatible(assetPack)
}
```
If your extension type is Self-Hosted, Unmanaged, the file Xcode generates has many functions in it for manual control over the download life cycle of your assets.
Load adapter assets in your app
After you configure an asset-downloader extension, you can start loading adapters. Before you download an adapter, remove any outdated adapters that might be on a person’s device:
SystemLanguageModel.Adapter.removeObsoleteAdapters()
Create an instance of SystemLanguageModel.Adapter using your adapter’s base name, but exclude the file extension. If a person’s device doesn’t have a compatible adapter downloaded, your asset-downloader extension starts downloading a compatible adapter asset pack:

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")
```
Initializing a SystemLanguageModel.Adapter starts a download automatically when a person launches your app for the first time or their device needs an updated adapter. Because adapters can have a large data size they can take some time to download, especially if a person is on Wi-Fi or a cell network. If a person doesn’t have a network connection, they aren’t able to use your adapter right away. This method shows how to track the download status of an adapter:

```swift
func checkAdapterDownload(name: String) async -> Bool {
    // Get the ID of the compatible adapter.
    let assetpackIDList = SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(
        name: name
    )


    if let assetPackID = assetpackIDList.first {
        // Get the download status asynchronous sequence.
        let statusUpdates = AssetPackManager.shared.statusUpdates(forAssetPackWithID: assetPackID)


        // Use the current status to update any loading UI.
        for await status in statusUpdates {
            switch status {
            case .began(let assetPack):
                // The download started.
            case .paused(let assetPack):
                // The download is in a paused state.
            case .downloading(let assetPack, let progress):
                // The download in progress.
            case .finished(let assetPack):
                // The download is complete and the adapter is ready to use.
                return true
            case .failed(let assetPack, let error):
                // The download failed.
                return false
            @unknown default:
                // The download encountered an unknown status.
                fatalError()
            }
        }
    }
}
```
For more details on tracking downloads for general assets, see Downloading Apple-hosted asset packs.
Before you attempt to use the adapter, you need to wait for the status to be in a AssetPackManager.DownloadStatusUpdate.finished(_:) state. The system returns AssetPackManager.DownloadStatusUpdate.finished(_:) immediately if no download is necessary.
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    // Adapt the base model with your adapter.
    let adaptedModel = SystemLanguageModel(adapter: adapter)
    
    // Start a session with the adapted model.
    let session = LanguageModelSession(model: adaptedModel)
    
    // Start prompting the adapted model.
}
```
Compile your draft model
A draft model is an optional step when training your adapter that can speed up inference. If your adapter includes a draft model, you can compile it for faster inference:
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    do {
        // You can use your adapter without compiling the draft model, or during
        // compilation, but running inference with your adapter might be slower.
        try await adapter.compile()
    } catch let error {
        // Handle the draft model compilation error.
    }
}
```
For more about training draft models, see the “Optionally train the draft model” section in Get started with Foundation Models adapter training.
Compiling a draft model is a computationally expensive step, so use the Background Tasks framework to configure a background task for your app. In your background task, call compile() on your adapter to start compilation. For more information about using background tasks, see Using background tasks to update your app.
Compilation doesn’t run every time a person uses your app:
- The first time a device downloads a new version of your adapter, a call to compile() fully compiles your draft model and saves it to the device.
- During subsequent launches of your app, a call to compile() checks for a saved compiled draft model and returns it immediately if it exists.
Important
Rate limiting protects device resources that are shared between all apps and processes. If the framework determines that a new compilation is necessary, it rate-limits the compilation process on all platforms, excluding macOS, to three draft model compilations per-app, per-day.
The full compilation process runs every time you launch your app through Xcode because Xcode assigns your app a new UUID for every launch. If you receive a rate-limiting error while testing your app, stop your app in Xcode and re-launch it to reset the rate counter.

## See Also

Loading the model with an adapter
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.


Property List Key
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
> iOS 26.0+
> iPadOS 26.0+
> macOS 26.0+
> visionOS 26.0+

## Details

Type
boolean
Attributes
Default: NO

## Discussion

Before submitting an app with this entitlement to the App Store, you must get permission to use the entitlement. To apply for the entitlement, log in to your Apple Developer Account with an Account Holder role and fill out the request form.


## Initializer


```swift
init(adapter:guardrails:)
```
Creates the base version of the model with an adapter.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
convenience init(
    adapter: SystemLanguageModel.Adapter,
    guardrails: SystemLanguageModel.Guardrails = .default
```
)

## See Also

Loading the model with an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.


# Structure

SystemLanguageModel.Adapter
Specializes the system language model for custom use cases.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Adapter
```

## Mentioned in


Loading and using a custom adapter with Foundation Models

## Overview

Use the base system model for most prompt engineering, guided generation, and tools. If you need to specialize the model, train a custom Adapter to alter the system model weights and optimize it for your custom task. Use custom adapters only if you’re comfortable training foundation models in Python.
Important
Be sure to re-train the adapter for every new version of the base system model that Apple releases. Adapters consume a large amount of storage space and isn’t recommended for most apps.
For more on custom adapters, see Get started with Foundation Models adapter training.

## Topics

Creating an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
init(fileURL: URL) throws
```
Creates an adapter from the file URL.

```swift
init(name: String) throws
```
Creates an adapter downloaded from the background assets framework.
Prepare the adapter

```swift
func compile() async throws
```
Prepares an adapter before being used with a LanguageModelSession. You should call this if your adapter has a draft model.
Getting the metadata

```swift
var creatorDefinedMetadata: [String : Any]
```
Values read from the creator defined field of the adapter’s metadata.
Removing obsolete adapters
static func removeObsoleteAdapters() throws
Remove all obsolete adapters that are no longer compatible with current system models.
Checking compatibility
static func compatibleAdapterIdentifiers(name: String) -> [String]
Get all compatible adapter identifiers compatible with current system models.
static func isCompatible(AssetPack) -> Bool
Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.
Getting the asset error

```swift
enum AssetError
```

## See Also

Loading the model with an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.



# Article

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.

## Overview

Use an adapter to adapt the on-device foundation model to fit your specific use case without needing to retrain the entire model from scratch. Before you can load a custom adapter, you first need to train one with an adapter training toolkit. The toolkit uses Python and Pytorch, and requires familiarity with training machine-learning models. After you train an adapter, you can use the toolkit to export a package in the format that Xcode and the Foundation Models framework expects.
When you train an adapter you need to make it available for deployment into your app. An adapter file is large — 160 MB or more — so don’t bundle them in your app. Instead, use App Store Connect, or host the asset on your server, and download the correct adapter for a person’s device on-demand.
Important
Each adapter is compatible with a single specific system model version. You must train a new adapter for every new base model version. A runtime error occurs if your app runs on a person’s device without a compatible adapter.
For more information about the adapter training toolkit, see Get started with Foundation Models adapter training. For more information about asset packs, see Background Assets.
Test a local adapter in Xcode
After you train an adapter with the adapter training toolkit, store your .fmadapter package files in a different directory from your app. Then, open .fmadapter packages with Xcode to locally preview each adapter’s metadata and version compatibility before you deploy the adapter.
If you train multiple adapters:
	1	Find the adapter package that’s compatible with the macOS version of the Mac on which you run Xcode.
	2	Select the compatible adapter file in Finder.
	3	Copy its full file path to the clipboard by pressing Option + Command + C.
	4	Initialize SystemLanguageModel.Adapter with the file path.
// The absolute path to your adapter.

```swift
let localURL = URL(filePath: "absolute/path/to/my_adapter.fmadapter")


```
// Initialize the adapter by using the local URL.

```swift
let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)
```
After you initialize an Adapter, create an instance of SystemLanguageModel with it:
// An instance of the the system language model using your adapter.

```swift
let customAdapterModel = SystemLanguageModel(adapter: adapter)


```
// Create a session and prompt the model.

```swift
let session = LanguageModelSession(model: customAdapterModel)
let response = try await session.respond(to: "Your prompt here")
```
Important
Only import adapter files into your Xcode project for local testing, then remove them before you publish your app. Adapter files are large, so download them on-demand by using Background Assets.
Testing adapters requires a physical device and isn’t supported on Simulator. When you’re ready to deploy adapters in your app, you need the com.apple.developer.foundation-model-adapter entitlement. You don’t need this entitlement to train or locally test adapters. To request access to use the entitlement, log in to Apple Developer and see Foundation Models Framework Adapter Entitlement.
Bundle adapters as asset packs
When people use your app they only need the specific adapter that’s compatible with their device. Host your adapter assets on a server and use Background Assets to manage downloads. For hosting, you can use your own server or have Apple host your adapter assets. For more information about Apple-hosted asset packs, see Overview of Apple-hosted asset packs.
The Background Assets framework has a type of asset pack specific to adapters that you create for the Foundation Models framework. The Foundation Models adapter training toolkit helps you bundle your adapters in the correct asset pack format. The toolkit uses the ba-package command line tool that’s included with Xcode 16 or later. If you train your adapters on a Linux GPU machine, see How to train adapters to set up a Python environment on your Mac. The adapter toolkit includes example code that shows how to create the asset pack in the correct format.
After you generate an asset pack for each adapter, upload the asset packs to your server. For more information about uploading Apple-hosted adapters, see Upload Apple-Hosted asset packs.
Configure an asset-download target in Xcode
To download adapters at runtime, you need to add an asset-downloader extension target to your Xcode project:
	1	In Xcode, choose File > New > Target.
	2	Choose the Background Download template under the Application Extension section.
	3	Click next.
	4	Enter a descriptive name, like “AssetDownloader”, for the product name.
	5	Select the type of extension.
	6	Click Finish.
The type of extension depends on whether you self-host them or Apple hosts them:
Apple-Hosted, Managed
Apple hosts your adapter assets.
Self-Hosted, Managed
You use your server and make each device’s operating system automatically handle the download life cycle.
Self-Hosted, Unmanaged
You use your server and manage the download life cycle.
After you create an asset-downloader extension target, check that your app target’s info property list contains the required fields specific to your extension type:
Apple-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
- BAUsesAppleHosting = YES
Self-Hosted, Managed

- BAHasManagedAssetPacks = YES
- BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.
If you use Self-Hosted, Unmanaged, then you don’t need additional keys. For more information about configuring background assets with an extension, see Configuring an unmanaged Background Assets project
Choose a compatible adapter at runtime
When you create an asset-downloader extension, Xcode generates a Swift file — BackgroundDownloadHandler.swift — that Background Assets uses to download your adapters. Open the Swift file in Xcode and fill in the code based on your target type. For Apple-Hosted, Managed or Self-Hosted, Managed extension types, complete the function shouldDownload with the following code that chooses an adapter asset compatible with the runtime device:

```swift
func shouldDownload(_ assetPack: AssetPack) -> Bool {
    // Check for any non-adapter assets your app has, like shaders. Remove the
    // check if your app doesn't have any non-adapter assets.
    if assetPack.id.hasPrefix("mygameshader") {
        // Return false to filter out asset packs, or true to allow download.
        return true
    }


    // Use the Foundation Models framework to check adapter compatibility with the runtime device.
    return SystemLanguageModel.Adapter.isCompatible(assetPack)
}
```
If your extension type is Self-Hosted, Unmanaged, the file Xcode generates has many functions in it for manual control over the download life cycle of your assets.
Load adapter assets in your app
After you configure an asset-downloader extension, you can start loading adapters. Before you download an adapter, remove any outdated adapters that might be on a person’s device:
SystemLanguageModel.Adapter.removeObsoleteAdapters()
Create an instance of SystemLanguageModel.Adapter using your adapter’s base name, but exclude the file extension. If a person’s device doesn’t have a compatible adapter downloaded, your asset-downloader extension starts downloading a compatible adapter asset pack:

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")
```
Initializing a SystemLanguageModel.Adapter starts a download automatically when a person launches your app for the first time or their device needs an updated adapter. Because adapters can have a large data size they can take some time to download, especially if a person is on Wi-Fi or a cell network. If a person doesn’t have a network connection, they aren’t able to use your adapter right away. This method shows how to track the download status of an adapter:

```swift
func checkAdapterDownload(name: String) async -> Bool {
    // Get the ID of the compatible adapter.
    let assetpackIDList = SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(
        name: name
    )


    if let assetPackID = assetpackIDList.first {
        // Get the download status asynchronous sequence.
        let statusUpdates = AssetPackManager.shared.statusUpdates(forAssetPackWithID: assetPackID)


        // Use the current status to update any loading UI.
        for await status in statusUpdates {
            switch status {
            case .began(let assetPack):
                // The download started.
            case .paused(let assetPack):
                // The download is in a paused state.
            case .downloading(let assetPack, let progress):
                // The download in progress.
            case .finished(let assetPack):
                // The download is complete and the adapter is ready to use.
                return true
            case .failed(let assetPack, let error):
                // The download failed.
                return false
            @unknown default:
                // The download encountered an unknown status.
                fatalError()
            }
        }
    }
}
```
For more details on tracking downloads for general assets, see Downloading Apple-hosted asset packs.
Before you attempt to use the adapter, you need to wait for the status to be in a AssetPackManager.DownloadStatusUpdate.finished(_:) state. The system returns AssetPackManager.DownloadStatusUpdate.finished(_:) immediately if no download is necessary.
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    // Adapt the base model with your adapter.
    let adaptedModel = SystemLanguageModel(adapter: adapter)
    
    // Start a session with the adapted model.
    let session = LanguageModelSession(model: adaptedModel)
    
    // Start prompting the adapted model.
}
```
Compile your draft model
A draft model is an optional step when training your adapter that can speed up inference. If your adapter includes a draft model, you can compile it for faster inference:
// Load the adapter.

```swift
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


```
// Wait for download to complete.

```swift
if await checkAdapterDownload(name: "myAdapter") {
    do {
        // You can use your adapter without compiling the draft model, or during
        // compilation, but running inference with your adapter might be slower.
        try await adapter.compile()
    } catch let error {
        // Handle the draft model compilation error.
    }
}
```
For more about training draft models, see the “Optionally train the draft model” section in Get started with Foundation Models adapter training.
Compiling a draft model is a computationally expensive step, so use the Background Tasks framework to configure a background task for your app. In your background task, call compile() on your adapter to start compilation. For more information about using background tasks, see Using background tasks to update your app.
Compilation doesn’t run every time a person uses your app:
- The first time a device downloads a new version of your adapter, a call to compile() fully compiles your draft model and saves it to the device.
- During subsequent launches of your app, a call to compile() checks for a saved compiled draft model and returns it immediately if it exists.
Important
Rate limiting protects device resources that are shared between all apps and processes. If the framework determines that a new compilation is necessary, it rate-limits the compilation process on all platforms, excluding macOS, to three draft model compilations per-app, per-day.
The full compilation process runs every time you launch your app through Xcode because Xcode assigns your app a new UUID for every launch. If you receive a rate-limiting error while testing your app, stop your app in Xcode and re-launch it to reset the rate counter.

## See Also

Loading the model with an adapter
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.

```swift
struct Adapter
```
Specializes the system language model for custom use cases.


Property List Key
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
> iOS 26.0+
> iPadOS 26.0+
> macOS 26.0+
> visionOS 26.0+

## Details

Type
boolean
Attributes
Default: NO

## Discussion

Before submitting an app with this entitlement to the App Store, you must get permission to use the entitlement. To apply for the entitlement, log in to your Apple Developer Account with an Account Holder role and fill out the request form.



## Initializer


```swift
init(fileURL:)
```
Creates an adapter from the file URL.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(fileURL: URL) throws
```

## Discussion


## Throws

An error of AssetLoadingError type when fileURL is invalid.

## See Also

Creating an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
init(name: String) throws
```
Creates an adapter downloaded from the background assets framework.



## Initializer


```swift
init(name:)
```
Creates an adapter downloaded from the background assets framework.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(name: String) throws
```

## Discussion


## Throws

An error of AssetLoadingError type when there are no compatible asset packs with this adapter name downloaded.

## See Also

Creating an adapter

Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

```swift
init(fileURL: URL) throws
```
Creates an adapter from the file URL.



## Instance Method

compile()
Prepares an adapter before being used with a LanguageModelSession. You should call this if your adapter has a draft model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
func compile() async throws
```

## Mentioned in


Loading and using a custom adapter with Foundation Models



## Instance Property

creatorDefinedMetadata
Values read from the creator defined field of the adapter’s metadata.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var creatorDefinedMetadata: [String : Any] { get }

```

## Type Method

removeObsoleteAdapters()
Remove all obsolete adapters that are no longer compatible with current system models.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func removeObsoleteAdapters() throws


## Type Method

compatibleAdapterIdentifiers(name:)
Get all compatible adapter identifiers compatible with current system models.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func compatibleAdapterIdentifiers(name: String) -> [String]

## Parameters

name
Name of the adapter.

## Return Value

All adapter identifiers compatible with current system models, listed in descending order in terms of system preference. You can determine which asset pack or on-demand resource to download with compatible adapter identifiers.
On devices that support Apple Intelligence, the result is guaranteed to be non-empty.

## See Also

Checking compatibility
static func isCompatible(AssetPack) -> Bool
Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.



## Type Method

isCompatible(_:)
Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func isCompatible(_ assetPack: AssetPack) -> Bool

## Discussion

Use this check when choosing an adapter asset pack to download. This check only validates the asset pack name and metadata, so initializing the adapter with init(name:) — or loading the adapter onto the base model with init(adapter:guardrails:) — may throw errors if the adapter has a compatibility issue despite having correct metadata.
Note
Run this check before you download an adapter asset pack to confirm if it’s usable on the runtime device.

## See Also

Checking compatibility
static func compatibleAdapterIdentifiers(name: String) -> [String]
Get all compatible adapter identifiers compatible with current system models.



# Enumeration

SystemLanguageModel.Adapter.AssetError
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum AssetError
```

## Topics

Getting the asset errors

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if there are no compatible adapters for the current system base model.

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided adapter name is invalid.

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided asset files are invalid.

```swift
struct Context
```
The context in which the error occurred.
Getting the error description

```swift
var errorDescription: String?
```
A string representation of the error description.

## Relationships


## Conforms To

- Error
- LocalizedError
- Sendable
- SendableMetatype


Case
SystemLanguageModel.Adapter.AssetError.compatibleAdapterNotFound(_:)
An error that happens if there are no compatible adapters for the current system base model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```

## See Also

Getting the asset errors

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided adapter name is invalid.

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided asset files are invalid.

```swift
struct Context
```
The context in which the error occurred.


Case
SystemLanguageModel.Adapter.AssetError.invalidAdapterName(_:)
An error that happens if the provided adapter name is invalid.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```

## See Also

Getting the asset errors

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if there are no compatible adapters for the current system base model.

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided asset files are invalid.

```swift
struct Context
```
The context in which the error occurred.


Case
SystemLanguageModel.Adapter.AssetError.invalidAsset(_:)
An error that happens if the provided asset files are invalid.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```

## See Also

Getting the asset errors

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if there are no compatible adapters for the current system base model.

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided adapter name is invalid.

```swift
struct Context
```
The context in which the error occurred.



# Structure

SystemLanguageModel.Adapter.AssetError.Context
The context in which the error occurred.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Context
```

## Topics

Creating a context

```swift
init(debugDescription: String)
```
Getting the debug description

```swift
let debugDescription: String
```
A debug description to help developers diagnose issues during development.

## Relationships


## Conforms To

- Sendable
- SendableMetatype

## See Also

Getting the asset errors

```swift
case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if there are no compatible adapters for the current system base model.

```swift
case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided adapter name is invalid.

```swift
case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)
```
An error that happens if the provided asset files are invalid.



## Initializer


```swift
init(debugDescription:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(debugDescription: String)


```

## Instance Property

debugDescription
A debug description to help developers diagnose issues during development.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
let debugDescription: String
```

## Discussion

This string is not localized and is not appropriate for display to end users.



## Instance Property

errorDescription
A string representation of the error description.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var errorDescription: String? { get }


```

## Instance Property

isAvailable
A convenience getter to check if the system is entirely ready.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
final var isAvailable: Bool { get }
```

## See Also

Checking model availability

```swift
var availability: SystemLanguageModel.Availability
```
The availability of the language model.

```swift
enum Availability
```
The availability status for a specific system language model.



## Instance Property

availability
The availability of the language model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
final var availability: SystemLanguageModel.Availability { get }
```

## See Also

Checking model availability

```swift
var isAvailable: Bool
```
A convenience getter to check if the system is entirely ready.

```swift
enum Availability
```
The availability status for a specific system language model.



# Enumeration

SystemLanguageModel.Availability
The availability status for a specific system language model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@frozen
enum Availability
```

## Overview


## See Also

availability

## Topics

Checking for availability

```swift
case available
```
The system is ready for making requests.

```swift
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```
Indicates that the system is not ready for requests.

```swift
enum UnavailableReason
```
The unavailable reason.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Checking model availability

```swift
var isAvailable: Bool
```
A convenience getter to check if the system is entirely ready.

```swift
var availability: SystemLanguageModel.Availability
```
The availability of the language model.


Case
SystemLanguageModel.Availability.available
The system is ready for making requests.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case available
```

## See Also

Checking for availability

```swift
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```
Indicates that the system is not ready for requests.

```swift
enum UnavailableReason
```
The unavailable reason.


Case
SystemLanguageModel.Availability.unavailable(_:)
Indicates that the system is not ready for requests.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```

## See Also

Checking for availability

```swift
case available
```
The system is ready for making requests.

```swift
enum UnavailableReason
```
The unavailable reason.



# Enumeration

SystemLanguageModel.Availability.UnavailableReason
The unavailable reason.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum UnavailableReason
```

## Topics

Getting the unavailable reasons

```swift
case appleIntelligenceNotEnabled
```
Apple Intelligence is not enabled on the system.

```swift
case deviceNotEligible
```
The device does not support Apple Intelligence.

```swift
case modelNotReady
```
The model(s) aren’t available on the user’s device.

## Relationships


## Conforms To

- Copyable
- Equatable
- Hashable
- Sendable
- SendableMetatype

## See Also

Checking for availability

```swift
case available
```
The system is ready for making requests.

```swift
case unavailable(SystemLanguageModel.Availability.UnavailableReason)
```
Indicates that the system is not ready for requests.

Case
SystemLanguageModel.Availability.UnavailableReason.appleIntelligenceNotEnabled
Apple Intelligence is not enabled on the system.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case appleIntelligenceNotEnabled
```

## See Also

Getting the unavailable reasons

```swift
case deviceNotEligible
```
The device does not support Apple Intelligence.

```swift
case modelNotReady
```
The model(s) aren’t available on the user’s device.

Case
SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible
The device does not support Apple Intelligence.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case deviceNotEligible
```

## See Also

Getting the unavailable reasons

```swift
case appleIntelligenceNotEnabled
```
Apple Intelligence is not enabled on the system.

```swift
case modelNotReady
```
The model(s) aren’t available on the user’s device.


Case
SystemLanguageModel.Availability.UnavailableReason.modelNotReady
The model(s) aren’t available on the user’s device.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case modelNotReady
```

## Discussion

Models are downloaded automatically based on factors like network status, battery level, and system load.

## See Also

Getting the unavailable reasons

```swift
case appleIntelligenceNotEnabled
```
Apple Intelligence is not enabled on the system.

```swift
case deviceNotEligible
```
The device does not support Apple Intelligence.



## Instance Property

supportedLanguages
Languages that the model supports.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
final var supportedLanguages: Set<Locale.Language> { get }
```

## Mentioned in


Supporting languages and locales with Foundation Models

## Discussion

To check if a given locale is considered supported by the model, use supportsLocale(_:), which will also take into consideration language fallbacks.




## Instance Method

supportsLocale(_:)
Returns a Boolean indicating whether the given locale is supported by the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final func supportsLocale(_ locale: Locale = Locale.current) -> Bool

## Mentioned in


Supporting languages and locales with Foundation Models

## Discussion

Use this method over supportedLanguages to check whether the given locale qualifies a user for using this model, as this method will take into consideration language fallbacks.



## Type Property

default
The base version of the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static let `default`: SystemLanguageModel
```

## Mentioned in


Generating content and performing tasks with Foundation Models

## Discussion

The base model is a generic model that is useful for a wide variety of applications, but is not specialized to any particular use case.


# Protocol

Tool
A tool that a model can call to gather information at runtime or perform side effects.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
protocol Tool<Arguments, Output> : Sendable
```

## Mentioned in


Generating content and performing tasks with Foundation Models

Categorizing and organizing data with content tags

Expanding generation with tool calling

## Overview

Tool calling gives the model the ability to call your code to incorporate up-to-date information like recent events and data from your app. A tool includes a name and a description that the framework puts in the prompt to let the model decide when and how often to call your tool.
A Tool defines a call(arguments:) method that takes arguments that conforms to ConvertibleFromGeneratedContent, and returns an output of any type that conforms to PromptRepresentable, allowing the model to understand and reason about in subsequent interactions. Typically, Output is a String or any Generable types.

```swift
struct FindContacts: Tool {
    let name = "findContacts"
    let description = "Find a specific number of contacts"


    @Generable
    struct Arguments {
        @Guide(description: "The number of contacts to get", .range(1...10))
        let count: Int
    }


    func call(arguments: Arguments) async throws -> [String] {
        var contacts: [CNContact] = []
        // Fetch a number of contacts using the arguments.
        let formattedContacts = contacts.map {
            "\($0.givenName) \($0.familyName)"
        }
        return formattedContacts
    }
}
```
Tools must conform to Sendable so the framework can run them concurrently. If the model needs to pass the output of one tool as the input to another, it executes back-to-back tool calls.
You control the life cycle of your tool, so you can track the state of it between calls to the model. For example, you might store a list of database records that you don’t want to reuse between tool calls.
Prompting the model with tools contributes to the available context window size. When you provide a tool in your generation request, the framework puts the tool definitions — name, description, parameter information — in the prompt so the model can decide when and how often to call the tool. After calling your tool, the framework returns the tool’s output back to the model for further processing.
To efficiently use tool calling:
- Reduce Guide(description:) descriptions to a short phrase each.
- Limit the number of tools you use to three to five.
- Include a tool only when its necessary for the task you want to perform.
- Run an essential tool before calling the model and integrate the tool’s output in the prompt directly.
If your session exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:). When you encounter the context window limit, consider breaking up tool calls across new LanguageModelSession instances. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Invoking a tool

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output
```
A language model will call this method when it wants to leverage this tool.
Required
associatedtype Arguments : ConvertibleFromGeneratedContent
The arguments that this tool should accept.
Required
associatedtype Output : PromptRepresentable
The output that this tool produces for the language model to reason about in subsequent interactions.
Required
Getting the tool properties

```swift
var description: String
```
A natural language description of when and how to use the tool.
Required

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
Required Default implementation provided.

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
Required Default implementation provided.

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.
Required Default implementation provided.

## Relationships

Inherits From
- Sendable
- SendableMetatype

## See Also

Tool calling

Expanding generation with tool calling
Build tools that enable the model to perform tasks that are specific to your use case.

Generate dynamic game content with guided generation and tools
Make gameplay more lively with AI generated dialog and encounters personalized to the player.



## Instance Method

call(arguments:)
A language model will call this method when it wants to leverage this tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output
```
Required

## Mentioned in


Expanding generation with tool calling

## Discussion

If errors are throw in the body of this method, they will be wrapped in a LanguageModelSession.ToolCallError and rethrown at the call site of respond(to:options:).
Note
This method may be invoked concurrently with itself or with other tools.

## See Also

Invoking a tool
associatedtype Arguments : ConvertibleFromGeneratedContent
The arguments that this tool should accept.
Required
associatedtype Output : PromptRepresentable
The output that this tool produces for the language model to reason about in subsequent interactions.
Required


Associated Type
Arguments
The arguments that this tool should accept.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
associatedtype Arguments : ConvertibleFromGeneratedContent
Required

## Mentioned in


Expanding generation with tool calling

## Discussion

Typically arguments are either a Generable type or GeneratedContent.

## See Also

Invoking a tool

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output
```
A language model will call this method when it wants to leverage this tool.
Required
associatedtype Output : PromptRepresentable
The output that this tool produces for the language model to reason about in subsequent interactions.
Required


Associated Type
Output
The output that this tool produces for the language model to reason about in subsequent interactions.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
associatedtype Output : PromptRepresentable
Required

## Discussion

Typically output is either a String or a Generable type.

## See Also

Invoking a tool

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output
```
A language model will call this method when it wants to leverage this tool.
Required
associatedtype Arguments : ConvertibleFromGeneratedContent
The arguments that this tool should accept.
Required



## Instance Property

description
A natural language description of when and how to use the tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var description: String { get }
```
Required

## See Also

Getting the tool properties

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
Required Default implementation provided.

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
Required Default implementation provided.

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.
Required Default implementation provided.



## Instance Property

includesSchemaInInstructions
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var includesSchemaInInstructions: Bool { get }
```
Required Default implementation provided.

## Discussion

The default implementation is true
Note
This should only be false if the model has been trained to have innate knowledge of this tool. For zero-shot prompting, it should always be true.

## Default Implementations

Tool Implementations

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

## See Also

Getting the tool properties

```swift
var description: String
```
A natural language description of when and how to use the tool.
Required

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
Required Default implementation provided.

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.
Required Default implementation provided.



## Instance Property

name
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var name: String { get }
```
Required Default implementation provided.

## Default Implementations

Tool Implementations

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.

## See Also

Getting the tool properties

```swift
var description: String
```
A natural language description of when and how to use the tool.
Required

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
Required Default implementation provided.

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.
Required Default implementation provided.



## Instance Property

parameters
A schema for the parameters this tool accepts.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var parameters: GenerationSchema { get }
```
Required Default implementation provided.

## Default Implementations

Tool Implementations

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.

## See Also

Getting the tool properties

```swift
var description: String
```
A natural language description of when and how to use the tool.
Required

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
Required Default implementation provided.

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
Required Default implementation provided.



# Structure

Instructions
Details you provide that define the model’s intended behavior on prompts.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Instructions
```

## Mentioned in


Generating content and performing tasks with Foundation Models

Improving the safety of generative model output

Prompting an on-device foundation model

Supporting languages and locales with Foundation Models

## Overview

Instructions are typically provided by you to define the role and behavior of the model. In the code below, the instructions specify that the model replies with topics rather than, for example, a recipe:

```swift
let instructions = """
    Suggest related topics. Keep them concise (three to seven words) and make sure they \
    build naturally from the person's topic.
    """


let session = LanguageModelSession(instructions: instructions)


let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)
```
Apple trains the model to obey instructions over any commands it receives in prompts, so don’t include untrusted content in instructions. For more on how instructions impact generation quality and safety, see Improving the safety of generative model output.
All input to the model contributes tokens to the context window of the LanguageModelSession — including the Instructions, Prompt, Tool, and Generable types, and the model’s responses. If your session exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:).
Instructions can consume a lot of tokens that contribute to the context window size. To reduce your instruction size:
- Write shorter instructions to save tokens.
- Provide only the information necessary to perform the task.
- Use concise and imperative language instead of indirect or jargon that the model might misinterpret.
- Aim for one to three paragraphs instead of including a significant amount of background information, policy, or extra content.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Creating instructions

```swift
init(_:)
struct InstructionsBuilder
```
A type that represents an instructions builder.

```swift
protocol InstructionsRepresentable
```
A type that can be represented as instructions.

## Relationships


## Conforms To

- Copyable
- InstructionsRepresentable
- Sendable
- SendableMetatype

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Initializer


```swift
init(_:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows
```
Show all declarations


## See Also

Creating instructions

```swift
struct InstructionsBuilder
```
A type that represents an instructions builder.

```swift
protocol InstructionsRepresentable
```
A type that can be represented as instructions.



# Structure

InstructionsBuilder
A type that represents an instructions builder.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@resultBuilder
struct InstructionsBuilder
```

## Topics

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.

## See Also

Creating instructions

```swift
init(_:)
protocol InstructionsRepresentable
```
A type that can be represented as instructions.



## Type Method

buildArray(_:)
Creates a builder with the an array of prompts.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildArray(_ instructions: [some InstructionsRepresentable]) -> Instructions

## See Also

Building instructions
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildBlock(_:)
Creates a builder with the a block.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildBlock<each I>(_ components: repeat each I) -> Instructions where repeat each I : InstructionsRepresentable

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildEither(first:)
Creates a builder with the first component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildEither(first component: some InstructionsRepresentable) -> Instructions

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildEither(second:)
Creates a builder with the second component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildEither(second component: some InstructionsRepresentable) -> Instructions

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildExpression(_:)
Creates a builder with a prompt expression.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildExpression(_ expression: Instructions) -> Instructions
Show all declarations


## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildLimitedAvailability(_:)
Creates a builder with a limited availability prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildLimitedAvailability(_ instructions: some InstructionsRepresentable) -> Instructions

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildOptional(_:)
Creates a builder with an optional component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildOptional(_ instructions: Instructions?) -> Instructions

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.



# Protocol

InstructionsRepresentable
A type that can be represented as instructions.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
protocol InstructionsRepresentable
```

## Topics

Getting the representation

```swift
var instructionsRepresentation: Instructions
```
An instance that represents the instructions.
Required Default implementation provided.

## Relationships


## Inherited By

- ConvertibleToGeneratedContent
- Generable

## Conforming Types

- GeneratedContent
- Instructions

## See Also

Creating instructions

```swift
init(_:)
struct InstructionsBuilder
```
A type that represents an instructions builder.



## Instance Property

instructionsRepresentation
An instance that represents the instructions.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@InstructionsBuilder
var instructionsRepresentation: Instructions { get }
```
Required Default implementation provided.

## Default Implementations

InstructionsRepresentable Implementations

```swift
var instructionsRepresentation: Instructions
```
An instance that represents the instructions.



## Initializer


```swift
init(model:tools:transcript:)
```
Start a session by rehydrating from a transcript.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
convenience init(
    model: SystemLanguageModel = .default,
    tools: [any Tool] = [],
    transcript: Transcript
```
)

## Discussion

- Parameters
- model: The language model to use for this session.
- transcript: A transcript to resume from.
- tools: Tools to make available to the model for this session.

## See Also

Creating a session from a transcript

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.



# Structure

Transcript
A linear history of entries that reflect an interaction with a session.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Transcript
```

## Mentioned in


Generating content and performing tasks with Foundation Models

## Overview

Use a Transcript to visualize previous instructions, prompts and model responses. If you use tool calling, a Transcript includes a history of tool calls and their results.

```swift
struct HistoryView: View {
    let session: LanguageModelSession


    var body: some View {
        ScrollView {
            ForEach(session.transcript) { entry in
                switch entry {
                case let .instructions(instructions):
                    MyInstructionsView(instructions)
                case let .prompt(prompt)
                    MyPromptView(prompt)
                case let .toolCalls(toolCalls):
                    MyToolCallsView(toolCalls)
                case let .toolOutput(toolOutput):
                    MyToolOutputView(toolOutput)
                case let .response(response):
                    MyResponseView(response)
                }
            }
        }
    }
}
```
When you create a new LanguageModelSession it doesn’t contain the state of a previous session. You can initialize a new session with a list of entries you get from a session transcript:
// Create a new session with the first and last entries from a previous session.

```swift
func newContextualSession(with originalSession: LanguageModelSession) -> LanguageModelSession {
    let allEntries = originalSession.transcript


    // Collect the entries to keep from the original session.
    let entries = [allEntries.first, allEntries.last].compactMap { $0 }
    let transcript = Transcript(entries: entries)


    // Create a new session with the result and preload the session resources.
    var session = LanguageModelSession(transcript: transcript)
    session.prewarm()
    return session
}
```

## Topics

Creating a transcript

```swift
init(entries: some Sequence<Transcript.Entry>)
```
Creates a transcript.

```swift
enum Entry
```
An entry in a transcript.

```swift
enum Segment
```
The types of segments that may be included in a transcript entry.
Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.

## Relationships


## Conforms To

- BidirectionalCollection
- Collection
- Copyable
- Decodable
- Encodable
- Equatable
- RandomAccessCollection
- Sendable
- SendableMetatype
- Sequence

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Initializer


```swift
init(entries:)
```
Creates a transcript.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(entries: some Sequence<Transcript.Entry> = [])
```

## Parameters

entries
An array of entries to seed the transcript.

## See Also

Creating a transcript

```swift
enum Entry
```
An entry in a transcript.

```swift
enum Segment
```
The types of segments that may be included in a transcript entry.



# Enumeration

Transcript.Entry
An entry in a transcript.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum Entry
```

## Overview

An individual entry in a transcript may represent instructions from you to the model, a prompt from a user, tool calls, or a response generated by the model.

## Topics

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Creating a transcript

```swift
init(entries: some Sequence<Transcript.Entry>)
```
Creates a transcript.

```swift
enum Segment
```
The types of segments that may be included in a transcript entry.


Case
Transcript.Entry.instructions(_:)
Instructions, typically provided by you, the developer.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case instructions(Transcript.Instructions)
```

## See Also

Creating an entry

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.


Case
Transcript.Entry.prompt(_:)
A prompt, typically sourced from an end user.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case prompt(Transcript.Prompt)
```

## See Also

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.


Case
Transcript.Entry.response(_:)
A response from the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case response(Transcript.Response)
```

## See Also

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.


Case
Transcript.Entry.toolCalls(_:)
A tool call containing a tool name and the arguments to invoke it with.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case toolCalls(Transcript.ToolCalls)
```

## See Also

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.


Case
Transcript.Entry.toolOutput(_:)
An tool output provided back to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case toolOutput(Transcript.ToolOutput)
```

## See Also

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.



# Enumeration

Transcript.Segment
The types of segments that may be included in a transcript entry.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum Segment
```

## Topics

Creating a segment

```swift
case structure(Transcript.StructuredSegment)
```
A segment containing structured content.

```swift
case text(Transcript.TextSegment)
```
A segment containing text.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Creating a transcript

```swift
init(entries: some Sequence<Transcript.Entry>)
```
Creates a transcript.

```swift
enum Entry
```
An entry in a transcript.


Case
Transcript.Segment.structure(_:)
A segment containing structured content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case structure(Transcript.StructuredSegment)
```

## See Also

Creating a segment

```swift
case text(Transcript.TextSegment)
```
A segment containing text.


Case
Transcript.Segment.text(_:)
A segment containing text.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case text(Transcript.TextSegment)
```

## See Also

Creating a segment

```swift
case structure(Transcript.StructuredSegment)
```
A segment containing structured content.



# Structure

Transcript.Instructions
Instructions you provide to the model that define its behavior.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Instructions
```

## Overview

Instructions are typically provided to define the role and behavior of the model. Apple trains the model to obey instructions over any commands it receives in prompts. This is a security mechanism to help mitigate prompt injection attacks.

## Topics

Creating instructions

```swift
init(id: String, segments: [Transcript.Segment], toolDefinitions: [Transcript.ToolDefinition])
```
Initialize instructions by describing how you want the model to behave using natural language.
Inspecting instructions

```swift
var segments: [Transcript.Segment]
```
The content of the instructions, in natural language.

```swift
var toolDefinitions: [Transcript.ToolDefinition]
```
A list of tools made available to the model.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:segments:toolDefinitions:)
```
Initialize instructions by describing how you want the model to behave using natural language.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    segments: [Transcript.Segment],
    toolDefinitions: [Transcript.ToolDefinition]
```
)

## Parameters

id
A unique identifier for this instructions segment.
segments
An array of segments that make up the instructions.
toolDefinitions
Tools that the model should be allowed to call.



## Instance Property

segments
The content of the instructions, in natural language.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var segments: [Transcript.Segment]
```

## Discussion

Note
Instructions are often provided in English even when the users interact with the model in another language.

## See Also

Inspecting instructions

```swift
var toolDefinitions: [Transcript.ToolDefinition]
```
A list of tools made available to the model.



## Instance Property

toolDefinitions
A list of tools made available to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var toolDefinitions: [Transcript.ToolDefinition]
```

## See Also

Inspecting instructions

```swift
var segments: [Transcript.Segment]
```
The content of the instructions, in natural language.



# Structure

Transcript.Prompt
A prompt from the user to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Prompt
```

## Overview

Prompts typically contain content sourced directly from the user, though you may choose to augment prompts by interpolating content from end users into a template that you control.

## Topics

Creating a prompt

```swift
init(id: String, segments: [Transcript.Segment], options: GenerationOptions, responseFormat: Transcript.ResponseFormat?)
```
Creates a prompt.
Inspecting a prompt

```swift
var id: String
```
The identifier of the prompt.

```swift
var responseFormat: Transcript.ResponseFormat?
```
An optional response format that describes the desired output structure.

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.

```swift
var options: GenerationOptions
```
Generation options associated with the prompt.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:segments:options:responseFormat:)
```
Creates a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    segments: [Transcript.Segment],
    options: GenerationOptions = GenerationOptions(),
    responseFormat: Transcript.ResponseFormat? = nil
```
)

## Parameters

id
A Generable type to use as the response format.
segments
An array of segments that make up the prompt.
options
Options that control how tokens are sampled from the distribution the model produces.
responseFormat
A response format that describes the output structure.



## Instance Property

id
The identifier of the prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var id: String
```

## See Also

Inspecting a prompt

```swift
var responseFormat: Transcript.ResponseFormat?
```
An optional response format that describes the desired output structure.

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.

```swift
var options: GenerationOptions
```
Generation options associated with the prompt.



## Instance Property

responseFormat
An optional response format that describes the desired output structure.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var responseFormat: Transcript.ResponseFormat?
```

## See Also

Inspecting a prompt

```swift
var id: String
```
The identifier of the prompt.

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.

```swift
var options: GenerationOptions
```
Generation options associated with the prompt.



## Instance Property

segments
Ordered prompt segments.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var segments: [Transcript.Segment]
```

## See Also

Inspecting a prompt

```swift
var id: String
```
The identifier of the prompt.

```swift
var responseFormat: Transcript.ResponseFormat?
```
An optional response format that describes the desired output structure.

```swift
var options: GenerationOptions
```
Generation options associated with the prompt.



## Instance Property

options
Generation options associated with the prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var options: GenerationOptions
```

## See Also

Inspecting a prompt

```swift
var id: String
```
The identifier of the prompt.

```swift
var responseFormat: Transcript.ResponseFormat?
```
An optional response format that describes the desired output structure.

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.



# Structure

Transcript.Response
A response from the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Response
```

## Topics

Creating a response

```swift
init(id: String, assetIDs: [String], segments: [Transcript.Segment])
```
Inspecting a response

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.

```swift
var assetIDs: [String]
```
Version aware identifiers for all assets used to generate this response.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.


nitializer

```swift
init(id:assetIDs:segments:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    assetIDs: [String],
    segments: [Transcript.Segment]
```
)



## Instance Property

segments
Ordered prompt segments.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var segments: [Transcript.Segment]
```

## See Also

Inspecting a response

```swift
var assetIDs: [String]
```
Version aware identifiers for all assets used to generate this response.



## Instance Property

assetIDs
Version aware identifiers for all assets used to generate this response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var assetIDs: [String]
```

## See Also

Inspecting a response

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.



# Structure

Transcript.ResponseFormat
Specifies a response format that the model must conform its output to.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ResponseFormat
```

## Topics

Creating a response format

```swift
init(schema: GenerationSchema)
```
Creates a response format with a schema.

```swift
init<Content>(type: Content.Type)
```
Creates a response format with type you specify.
Inspecting a response format

```swift
var name: String
```
A name associated with the response format.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(schema:)
```
Creates a response format with a schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(schema: GenerationSchema)
```

## Parameters

schema
A schema to use as the response format.

## See Also

Creating a response format

```swift
init<Content>(type: Content.Type)
```
Creates a response format with type you specify.



## Initializer


```swift
init(type:)
```
Creates a response format with type you specify.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init<Content>(type: Content.Type) where Content : Generable
```

## Parameters

type
A Generable type to use as the response format.

## See Also

Creating a response format

```swift
init(schema: GenerationSchema)
```
Creates a response format with a schema.



## Instance Property

name
A name associated with the response format.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var name: String { get }


```

# Structure

Transcript.StructuredSegment
A segment containing structured content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct StructuredSegment
```

## Topics

Creating a structured segment

```swift
init(id: String, source: String, content: GeneratedContent)
```
Inspecting a structured segment

```swift
var content: GeneratedContent
```
The content of the segment.

```swift
var source: String
```
A source that be used to understand which type content represents.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:source:content:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    source: String,
    content: GeneratedContent
```
)



## Instance Property

content
The content of the segment.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var content: GeneratedContent { get set }
```

## See Also

Inspecting a structured segment

```swift
var source: String
```
A source that be used to understand which type content represents.



## Instance Property

source
A source that be used to understand which type content represents.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var source: String
```

## See Also

Inspecting a structured segment

```swift
var content: GeneratedContent
```
The content of the segment.



# Structure

Transcript.TextSegment
A segment containing text.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct TextSegment
```

## Topics

Creating a text segment

```swift
init(id: String, content: String)
```
Inspecting a text segment

```swift
var content: String
```

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:content:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    content: String
```
)



## Instance Property

content
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var content: String


```

# Structure

Transcript.ToolCall
A tool call generated by the model containing the name of a tool and arguments to pass to it.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ToolCall
```

## Topics

Creating a tool call

```swift
init(id: String, toolName: String, arguments: GeneratedContent)
```
Inspecting a tool call

```swift
var arguments: GeneratedContent
```
Arguments to pass to the invoked tool.

```swift
var toolName: String
```
The name of the tool being invoked.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:toolName:arguments:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String,
    toolName: String,
    arguments: GeneratedContent
```
)



## Instance Property

arguments
Arguments to pass to the invoked tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var arguments: GeneratedContent { get set }
```

## See Also

Inspecting a tool call

```swift
var toolName: String
```
The name of the tool being invoked.



## Instance Property

toolName
The name of the tool being invoked.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var toolName: String
```

## See Also

Inspecting a tool call

```swift
var arguments: GeneratedContent
```
Arguments to pass to the invoked tool.



# Structure

Transcript.ToolCalls
A collection tool calls generated by the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ToolCalls
```

## Topics

Creating a tool calls

```swift
init<S>(id: String, S)
```

## Relationships


## Conforms To

- BidirectionalCollection
- Collection
- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- RandomAccessCollection
- Sendable
- SendableMetatype
- Sequence

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:_:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init<S>(
    id: String = UUID().uuidString,
    _ calls: S
```
) where S : Sequence, S.Element == Transcript.ToolCall


# Structure

Transcript.ToolDefinition
A definition of a tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ToolDefinition
```

## Topics

Creating a tool definition

```swift
init(name: String, description: String, parameters: GenerationSchema)
init(tool: some Tool)
```
Inspecting a tool definition

```swift
var description: String
```
A description of how and when to use the tool.

```swift
var name: String
```
The tool’s name.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(name:description:parameters:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    name: String,
    description: String,
    parameters: GenerationSchema
```
)

## See Also

Creating a tool definition

```swift
init(tool: some Tool)


```

## Initializer


```swift
init(tool:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(tool: some Tool)
```

## See Also

Creating a tool definition

```swift
init(name: String, description: String, parameters: GenerationSchema)


```

## Instance Property

description
A description of how and when to use the tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var description: String
```

## See Also

Inspecting a tool definition

```swift
var name: String
```
The tool’s name.



## Instance Property

name
The tool’s name.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var name: String
```

## See Also

Inspecting a tool definition

```swift
var description: String
```
A description of how and when to use the tool.



# Structure

Transcript.ToolOutput
A tool output provided back to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ToolOutput
```

## Topics

Creating a tool output

```swift
init(id: String, toolName: String, segments: [Transcript.Segment])
```
Inspecting a tool output

```swift
var id: String
```
A unique id for this tool output.

```swift
var segments: [Transcript.Segment]
```
Segments of the tool output.

```swift
var toolName: String
```
The name of the tool that produced this output.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.



## Initializer


```swift
init(id:toolName:segments:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String,
    toolName: String,
    segments: [Transcript.Segment]
```
)



## Instance Property

id
A unique id for this tool output.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var id: String
```

## See Also

Inspecting a tool output

```swift
var segments: [Transcript.Segment]
```
Segments of the tool output.

```swift
var toolName: String
```
The name of the tool that produced this output.



## Instance Property

segments
Segments of the tool output.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var segments: [Transcript.Segment]
```

## See Also

Inspecting a tool output

```swift
var id: String
```
A unique id for this tool output.

```swift
var toolName: String
```
The name of the tool that produced this output.



## Instance Property

toolName
The name of the tool that produced this output.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var toolName: String
```

## See Also

Inspecting a tool output

```swift
var id: String
```
A unique id for this tool output.

```swift
var segments: [Transcript.Segment]
```
Segments of the tool output.



## Instance Method

prewarm(promptPrefix:)
Loads the resources required for this session into memory, and optionally caches a prefix of your prompt to reduce request latency.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final func prewarm(promptPrefix: Prompt? = nil)

## Mentioned in


Analyzing the runtime performance of your Foundation Models app

## Discussion

Use this method when you know a person will launch and interact with your session within a few seconds to preload the required session resources. For example, you might call this method when a person begins typing into a text field.
If you have a prefix for a future prompt, passing it to this method allows the system to process the prompt eagerly and reduce latency for the future request.
Important
Only use this method when you have at least one second before calling a respond method, like respond(to:options:) or streamResponse(to:options:).
Calling this method doesn’t guarantee that the system loads your resources immediately, particularly if your app is running in the background or the system is under load.



## Instance Property

isResponding
A Boolean value that indicates a response is being generated.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
final var isResponding: Bool { get }
```

## Mentioned in


Generating content and performing tasks with Foundation Models

## Discussion

Important
You should not call any of the respond methods while this property is true.
Disable buttons and other interactions to prevent users from submitting a second prompt while the model is responding to their first prompt.

```swift
struct ShopView: View {
    @State var session = LanguageModelSession()
    @State var joke = ""


    var body: some View {
        Text(joke)
        Button("Generate joke") {
            Task {
                assert(!session.isResponding, "It should not be possible to tap this button while the model is responding")
                joke = try await session.respond(to: "Tell me a joke").content
            }
        }
        .disabled(session.isResponding) // Prevent concurrent calls to respond
    }
}
```

## See Also

Inspecting session properties

```swift
var transcript: Transcript
```
A full history of interactions, including user inputs and model responses.



## Instance Property

transcript
A full history of interactions, including user inputs and model responses.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
final var transcript: Transcript { get }
```

## Mentioned in


Expanding generation with tool calling

## See Also

Inspecting session properties

```swift
var isResponding: Bool
```
A Boolean value that indicates a response is being generated.



## Instance Method

respond(options:prompt:)
Produces a response to a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@discardableResult nonisolated(nonsending)
final func respond(

```swift
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
```
) async throws -> LanguageModelSession.Response<String>

## Parameters

options
GenerationOptions that control how tokens are sampled from the distribution the model produces.
prompt
A prompt for the model to respond to.

## Return Value

A string composed of the tokens produced by sampling model output.

## See Also

Generating a request

```swift
func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>
```
Produces a generable object as a response to a prompt.

```swift
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>
```
Produces a generated content type as a response to a prompt and schema.

```swift
func respond(to:options:)
```
Produces a response to a prompt.

```swift
func respond(to:generating:includeSchemaInPrompt:options:)
```
Produces a generable object as a response to a prompt.

```swift
func respond(to:schema:includeSchemaInPrompt:options:)
```
Produces a generated content type as a response to a prompt and schema.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Response
```
A structure that stores the output of a response call.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Instance Method

respond(generating:includeSchemaInPrompt:options:prompt:)
Produces a generable object as a response to a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@discardableResult nonisolated(nonsending)
final func respond<Content>(

```swift
    generating type: Content.Type = Content.self,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
```
) async throws -> LanguageModelSession.Response<Content> where Content : Generable

## Parameters

type
A type to produce as the response.
includeSchemaInPrompt
Inject the schema into the prompt to bias the model.
options
Options that control how tokens are sampled from the distribution the model produces.
prompt
A prompt for the model to respond to.

## Return Value

GeneratedContent containing the fields and values defined in the schema.

## Discussion

Consider using the default value of true for includeSchemaInPrompt. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

Generating a request

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>
```
Produces a response to a prompt.

```swift
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>
```
Produces a generated content type as a response to a prompt and schema.

```swift
func respond(to:options:)
```
Produces a response to a prompt.

```swift
func respond(to:generating:includeSchemaInPrompt:options:)
```
Produces a generable object as a response to a prompt.

```swift
func respond(to:schema:includeSchemaInPrompt:options:)
```
Produces a generated content type as a response to a prompt and schema.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Response
```
A structure that stores the output of a response call.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Instance Method

respond(schema:includeSchemaInPrompt:options:prompt:)
Produces a generated content type as a response to a prompt and schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@discardableResult nonisolated(nonsending)
final func respond(

```swift
    schema: GenerationSchema,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
```
) async throws -> LanguageModelSession.Response<GeneratedContent>

## Parameters

schema
A schema to guide the output with.
includeSchemaInPrompt
Inject the schema into the prompt to bias the model.
options
Options that control how tokens are sampled from the distribution the model produces.
prompt
A prompt for the model to respond to.

## Return Value

GeneratedContent containing the fields and values defined in the schema.

## Discussion

Consider using the default value of true for includeSchemaInPrompt. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

Generating a request

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>
```
Produces a response to a prompt.

```swift
func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>
```
Produces a generable object as a response to a prompt.

```swift
func respond(to:options:)
```
Produces a response to a prompt.

```swift
func respond(to:generating:includeSchemaInPrompt:options:)
```
Produces a generable object as a response to a prompt.

```swift
func respond(to:schema:includeSchemaInPrompt:options:)
```
Produces a generated content type as a response to a prompt and schema.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Response
```
A structure that stores the output of a response call.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Instance Method

respond(to:options:)
Produces a response to a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@discardableResult nonisolated(nonsending)
final func respond(

```swift
    to prompt: Prompt,
    options: GenerationOptions = GenerationOptions()
```
) async throws -> LanguageModelSession.Response<String>
Show all declarations


## Parameters

prompt
A prompt for the model to respond to.
options
GenerationOptions that control how tokens are sampled from the distribution the model produces.

## Return Value

A string composed of the tokens produced by sampling model output.

## Mentioned in


Supporting languages and locales with Foundation Models

## See Also

Generating a request

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>
```
Produces a response to a prompt.

```swift
func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>
```
Produces a generable object as a response to a prompt.

```swift
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>
```
Produces a generated content type as a response to a prompt and schema.

```swift
func respond(to:generating:includeSchemaInPrompt:options:)
```
Produces a generable object as a response to a prompt.

```swift
func respond(to:schema:includeSchemaInPrompt:options:)
```
Produces a generated content type as a response to a prompt and schema.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Response
```
A structure that stores the output of a response call.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Instance Method

respond(to:generating:includeSchemaInPrompt:options:)
Produces a generable object as a response to a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@discardableResult nonisolated(nonsending)
final func respond<Content>(

```swift
    to prompt: Prompt,
    generating type: Content.Type = Content.self,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions()
```
) async throws -> LanguageModelSession.Response<Content> where Content : Generable
Show all declarations


## Parameters

prompt
A prompt for the model to respond to.
type
A type to produce as the response.
includeSchemaInPrompt
Inject the schema into the prompt to bias the model.
options
Options that control how tokens are sampled from the distribution the model produces.

## Return Value

GeneratedContent containing the fields and values defined in the schema.

## Discussion

Consider using the default value of true for includeSchemaInPrompt. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

Generating a request

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>
```
Produces a response to a prompt.

```swift
func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>
```
Produces a generable object as a response to a prompt.

```swift
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>
```
Produces a generated content type as a response to a prompt and schema.

```swift
func respond(to:options:)
```
Produces a response to a prompt.

```swift
func respond(to:schema:includeSchemaInPrompt:options:)
```
Produces a generated content type as a response to a prompt and schema.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Response
```
A structure that stores the output of a response call.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Instance Method

respond(to:schema:includeSchemaInPrompt:options:)
Produces a generated content type as a response to a prompt and schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@discardableResult nonisolated(nonsending)
final func respond(

```swift
    to prompt: Prompt,
    schema: GenerationSchema,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions()
```
) async throws -> LanguageModelSession.Response<GeneratedContent>
Show all declarations


## Parameters

prompt
A prompt for the model to respond to.
schema
A schema to guide the output with.
includeSchemaInPrompt
Inject the schema into the prompt to bias the model.
options
Options that control how tokens are sampled from the distribution the model produces.

## Return Value

GeneratedContent containing the fields and values defined in the schema.

## Discussion

Consider using the default value of true for includeSchemaInPrompt. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

Generating a request

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>
```
Produces a response to a prompt.

```swift
func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>
```
Produces a generable object as a response to a prompt.

```swift
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>
```
Produces a generated content type as a response to a prompt and schema.

```swift
func respond(to:options:)
```
Produces a response to a prompt.

```swift
func respond(to:generating:includeSchemaInPrompt:options:)
```
Produces a generable object as a response to a prompt.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Response
```
A structure that stores the output of a response call.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



# Structure

Prompt
A prompt from a person to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Prompt
```

## Mentioned in


Generating content and performing tasks with Foundation Models

Prompting an on-device foundation model

## Overview

Prompts can contain content written by you, an outside source, or input directly from people using your app. You can initialize a Prompt from a string literal:

```swift
let prompt = Prompt("What are miniature schnauzers known for?")
```
Use PromptBuilder to dynamically control the prompt’s content based on your app’s state. The code below shows that if the Boolean is true, the prompt includes a second line of text:

```swift
let responseShouldRhyme = true
let prompt = Prompt {
    "Answer the following question from the user: \(userInput)"
    if responseShouldRhyme {
        "Your response MUST rhyme!"
    }
}
```
If your prompt includes input from people, consider wrapping the input in a string template with your own prompt to better steer the model’s response. For more information on handling inputs in your prompts, see Improving the safety of generative model output.
All input to the model contributes tokens to the context window of the LanguageModelSession — including the Instructions, Prompt, Tool, and Generable types, and the model’s responses. If your session exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:).
Prompts can consume a lot of tokens, especially when you send multiple prompts to the same session. To reduce your prompt size when you exceed the context window size:
- Write shorter prompts to save tokens.
- Provide only the information necessary to perform the task.
- Use concise and imperative language instead of indirect or jargon that the model might misinterpret.
- Use a clear verb that tells the model what to do, like “Generate”, “List”, or “Summarize”.
- Include the target response length you want, like “In three sentences” or “List five reasons”.
Prompting the same session eventually leads to exceeding the context window size. When that happens, create a new context window by initializing a new instance of LanguageModelSession. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Creating a prompt

```swift
init(_:)
struct PromptBuilder
```
A type that represents a prompt builder.

```swift
protocol PromptRepresentable
```
A type whose value can represent a prompt.

## Relationships


## Conforms To

- Copyable
- PromptRepresentable
- Sendable
- SendableMetatype

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Initializer


```swift
init(_:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(@PromptBuilder _ content: () throws -> Prompt) rethrows
```
Show all declarations


## See Also

Creating a prompt

```swift
struct PromptBuilder
```
A type that represents a prompt builder.

```swift
protocol PromptRepresentable
```
A type whose value can represent a prompt.



# Structure

PromptBuilder
A type that represents a prompt builder.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@resultBuilder
struct PromptBuilder
```

## Topics

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.

## See Also

Creating a prompt

```swift
init(_:)
protocol PromptRepresentable
```
A type whose value can represent a prompt.



## Type Method

buildArray(_:)
Creates a builder with the an array of prompts.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt

## See Also

Building a prompt
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildBlock(_:)
Creates a builder with the a block.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P : PromptRepresentable

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildEither(first:)
Creates a builder with the first component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildEither(first component: some PromptRepresentable) -> Prompt

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildEither(second:)
Creates a builder with the second component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildEither(second component: some PromptRepresentable) -> Prompt

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildExpression(_:)
Creates a builder with a prompt expression.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildExpression(_ expression: Prompt) -> Prompt
Show all declarations


## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildLimitedAvailability(_:)
Creates a builder with a limited availability prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildLimitedAvailability(_ prompt: some PromptRepresentable) -> Prompt

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildOptional(_:)
Creates a builder with an optional component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildOptional(_ component: Prompt?) -> Prompt

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.



# Protocol

PromptRepresentable
A type whose value can represent a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
protocol PromptRepresentable
```

## Overview

Important
Conformance to this protocol is provided automatically by the @Generable macro, you should not override its implementations. Overriding may negatively impact runtime performance and cause bugs.
For types that are not Generable, you may provide your own implementation.
Experiment with different representations to find one that works well for your type. Generally, any format that is easily understandable to humans will work well for the model as well.

```swift
struct FamousHistoricalFigure: PromptRepresentable {
    var name: String
    var biggestAccomplishment: String


    var promptRepresentation: Prompt {
        """
        Famous Historical Figure:
        - name: \(name)
        - best known for: \(biggestAccomplishment)
        """
    }
}


let response = try await LanguageModelSession().respond {
    "Tell me more about..."
    FamousHistoricalFigure(
        name: "Albert Einstein",
        biggestAccomplishment: "Theory of Relativity"
    )
}
```

## Topics

Getting the representation

```swift
var promptRepresentation: Prompt
```
An instance that represents a prompt.
Required Default implementation provided.

## Relationships


## Inherited By

- ConvertibleToGeneratedContent
- Generable

## Conforming Types

- GeneratedContent
- Prompt

## See Also

Creating a prompt

```swift
init(_:)
struct PromptBuilder
```
A type that represents a prompt builder.



## Instance Property

promptRepresentation
An instance that represents a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@PromptBuilder
var promptRepresentation: Prompt { get }
```
Required Default implementation provided.

## Default Implementations

PromptRepresentable Implementations

```swift
var promptRepresentation: Prompt
```
An instance that represents a prompt.



# Structure

LanguageModelSession.Response
A structure that stores the output of a response call.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Response<Content> where Content : Generable
```

## Topics

Getting the response content

```swift
let content: Content
```
The response content.

```swift
let rawContent: GeneratedContent
```
The raw response content.
Getting the transcript entries

```swift
let transcriptEntries: ArraySlice<Transcript.Entry>
```
The list of transcript entries.

## See Also

Generating a request

```swift
func respond(options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<String>
```
Produces a response to a prompt.

```swift
func respond<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<Content>
```
Produces a generable object as a response to a prompt.

```swift
func respond(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) async throws -> LanguageModelSession.Response<GeneratedContent>
```
Produces a generated content type as a response to a prompt and schema.

```swift
func respond(to:options:)
```
Produces a response to a prompt.

```swift
func respond(to:generating:includeSchemaInPrompt:options:)
```
Produces a generable object as a response to a prompt.

```swift
func respond(to:schema:includeSchemaInPrompt:options:)
```
Produces a generated content type as a response to a prompt and schema.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Instance Property

content
The response content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
let content: Content
```

## See Also

Getting the response content

```swift
let rawContent: GeneratedContent
```
The raw response content.



## Instance Property

rawContent
The raw response content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
let rawContent: GeneratedContent
```

## Discussion

When Content is GeneratedContent, this is the same as content.

## See Also

Getting the response content

```swift
let content: Content
```
The response content.



## Instance Property

transcriptEntries
The list of transcript entries.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
let transcriptEntries: ArraySlice<Transcript.Entry>


```

# Structure

GenerationOptions
Options that control how the model generates its response to a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct GenerationOptions
```

## Mentioned in


Generating content and performing tasks with Foundation Models

## Overview

Generation options determine the decoding strategy the framework uses to adjust the way the model chooses output tokens. When you interact with the model, it converts your input to a token sequence, and uses it to generate the response.
Only use maximumResponseTokens when you need to protect against unexpectedly verbose responses. Enforcing a strict token response limit can lead to the model producing malformed results or gramatically incorrect responses.
All input to the model contributes tokens to the context window of the LanguageModelSession — including the Instructions, Prompt, Tool, and Generable types, and the model’s responses. If your session exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:). For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Creating options

```swift
init(sampling: GenerationOptions.SamplingMode?, temperature: Double?, maximumResponseTokens: Int?)
```
Creates generation options that control token sampling behavior.
Configuring the response tokens

```swift
var maximumResponseTokens: Int?
```
The maximum number of tokens the model is allowed to produce in its response.
Configuring the sampling mode

```swift
var sampling: GenerationOptions.SamplingMode?
```
A sampling strategy for how the model picks tokens when generating a response.

```swift
struct SamplingMode
```
A type that defines how values are sampled from a probability distribution.
Configuring the temperature

```swift
var temperature: Double?
```
Temperature influences the confidence of the models response.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.



## Initializer


```swift
init(sampling:temperature:maximumResponseTokens:)
```
Creates generation options that control token sampling behavior.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    sampling: GenerationOptions.SamplingMode? = nil,
    temperature: Double? = nil,
    maximumResponseTokens: Int? = nil
```
)

## Parameters

sampling
A strategy to use for sampling from a distribution.
temperature
Increasing temperature makes it possible for the model to produce less likely responses. Must be between 0 and 1, inclusive.
maximumResponseTokens
The maximum number of tokens the model is allowed to produce before being artificially halted. Must be positive.



## Instance Property

maximumResponseTokens
The maximum number of tokens the model is allowed to produce in its response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var maximumResponseTokens: Int?
```

## Discussion

If the model produce maximumResponseTokens before it naturally completes its response, the response will be terminated early. No error will be thrown. This property can be used to protect against unexpectedly verbose responses and runaway generations.
If no value is specified, then the model is allowed to produce the longest answer its context size supports. If the response exceeds that limit without terminating, an error will be thrown.



## Instance Property

sampling
A sampling strategy for how the model picks tokens when generating a response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var sampling: GenerationOptions.SamplingMode?
```

## Discussion

When you execute a prompt on a model, the model produces a probability for every token in its vocabulary. The sampling strategy controls how the model narrows down the list of tokens to consider during that process. A strategy that picks the single most likely token yields a predictable response every time, but other strategies offer results that often sound more natural to a person.
Note
Leaving the sampling nil lets the system choose a a reasonable default on your behalf.

## See Also

Configuring the sampling mode

```swift
struct SamplingMode
```
A type that defines how values are sampled from a probability distribution.



# Structure

GenerationOptions.SamplingMode
A type that defines how values are sampled from a probability distribution.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct SamplingMode
```

## Overview

A model builds its response to a prompt in a loop. At each iteration in the loop the model produces a probability distribution for all the tokens in its vocabulary. The sampling mode controls how a token is selected from that distribution.

## Topics

Sampling options
static var greedy: GenerationOptions.SamplingMode
A sampling mode that always chooses the most likely token.
static func random(probabilityThreshold: Double, seed: UInt64?) -> GenerationOptions.SamplingMode
A mode that considers a variable number of high-probability tokens based on the specified threshold.
static func random(top: Int, seed: UInt64?) -> GenerationOptions.SamplingMode
A sampling mode that considers a fixed number of high-probability tokens.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Configuring the sampling mode

```swift
var sampling: GenerationOptions.SamplingMode?
```
A sampling strategy for how the model picks tokens when generating a response.



## Type Property

greedy
A sampling mode that always chooses the most likely token.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static var greedy: GenerationOptions.SamplingMode { get }
```

## Discussion

Using this mode will always result in the same output for a given input. Responses produced with greedy sampling are statistically likely, but may lack the human-like quality and variety of other sampling strategies.

## See Also

Sampling modes random(top:seed:) and random(probabilityThreshold:seed:)

## See Also

Sampling options
static func random(probabilityThreshold: Double, seed: UInt64?) -> GenerationOptions.SamplingMode
A mode that considers a variable number of high-probability tokens based on the specified threshold.
static func random(top: Int, seed: UInt64?) -> GenerationOptions.SamplingMode
A sampling mode that considers a fixed number of high-probability tokens.



## Type Method

random(probabilityThreshold:seed:)
A mode that considers a variable number of high-probability tokens based on the specified threshold.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func random(

```swift
    probabilityThreshold: Double,
    seed: UInt64? = nil
```
) -> GenerationOptions.SamplingMode

## Parameters

probabilityThreshold
A number between 0.0 and 1.0 that increases sampling pool size.
seed
An optional random seed used to make output more deterministic.

## Discussion

Also known as top-p or nucleus sampling.
With nucleus sampling, tokens are sorted by probability and added to a pool of candidates until the cumulative probability of the pool exceeds the specified threshold, and then a token is sampled from the pool.
Because the number of tokens isn’t predetermined, the selection pool size will be larger when the distribution is flat and smaller when it is spikey. This variability can lead to a wider variety of options to choose from, and potentially more creative responses.
Note
Setting a random seed is not guaranteed to result in fully deterministic output. It is best effort.

## See Also

Sampling modes greedy and random(top:seed:)

## See Also

Sampling options
static var greedy: GenerationOptions.SamplingMode
A sampling mode that always chooses the most likely token.
static func random(top: Int, seed: UInt64?) -> GenerationOptions.SamplingMode
A sampling mode that considers a fixed number of high-probability tokens.



## Type Method

random(top:seed:)
A sampling mode that considers a fixed number of high-probability tokens.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func random(

```swift
    top k: Int,
    seed: UInt64? = nil
```
) -> GenerationOptions.SamplingMode

## Parameters

k
The number of tokens to consider.
seed
An optional random seed used to make output more deterministic.

## Discussion

Also known as top-k.
During the token-selection process, the vocabulary is sorted by probability a token is selected from among the top K candidates. Smaller values of K will ensure only the most probable tokens are candidates for selection, resulting in more deterministic and confident answers. Larger values of K will allow less probably tokens to be selected, raising non-determinism and creativity.
Note
Setting a random seed is not guaranteed to result in fully deterministic output. It is best effort.

## See Also

Sampling modes greedy and random(probabilityThreshold:seed:)

## See Also

Sampling options
static var greedy: GenerationOptions.SamplingMode
A sampling mode that always chooses the most likely token.
static func random(probabilityThreshold: Double, seed: UInt64?) -> GenerationOptions.SamplingMode
A mode that considers a variable number of high-probability tokens based on the specified threshold.



## Instance Property

temperature
Temperature influences the confidence of the models response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var temperature: Double?
```

## Discussion

The value of this property must be a number between 0 and 1 inclusive.
Temperature is an adjustment applied to the probability distribution prior to sampling. A value of 1 results in no adjustment. Values less than 1 will make the probability distribution sharper, with already likely tokens becoming even more likely.
The net effect is that low temperatures manifest as more stable and predictable responses, while high temperatures give the model more creative license.
Note
Leaving temperature nil lets the system choose a reasonable default on your behalf.



## Instance Method

streamResponse(to:options:)
Produces a response stream to a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final func streamResponse(

```swift
    to prompt: Prompt,
    options: GenerationOptions = GenerationOptions()
```
) -> sending LanguageModelSession.ResponseStream<String>
Show all declarations


## Parameters

prompt
A specific prompt for the model to respond to.
options
GenerationOptions that control how tokens are sampled from the distribution the model produces.

## Return Value

A response stream that produces aggregated tokens.

## Discussion

Important
If running in the background, use the non-streaming respond(to:options:) method to reduce the likelihood of encountering LanguageModelSession.GenerationError.rateLimited(_:) errors.

## See Also

Streaming a response

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.



## Instance Method

streamResponse(to:generating:includeSchemaInPrompt:options:)
Produces a response stream to a prompt and schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final func streamResponse<Content>(

```swift
    to prompt: Prompt,
    generating type: Content.Type = Content.self,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions()
```
) -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable
Show all declarations


## Parameters

prompt
A prompt for the model to respond to.
type
A type to produce as the response.
includeSchemaInPrompt
Inject the schema into the prompt to bias the model.
options
Options that control how tokens are sampled from the distribution the model produces.

## Return Value

A response stream that produces GeneratedContent containing the fields and values defined in the schema.

## Discussion

Consider using the default value of true for includeSchemaInPrompt. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.
Important
If running in the background, use the non-streaming respond(to:options:) method to reduce the likelihood of encountering LanguageModelSession.GenerationError.rateLimited(_:) errors.

## See Also

Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.



## Instance Method

streamResponse(to:schema:includeSchemaInPrompt:options:)
Produces a response stream to a prompt and schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final func streamResponse(

```swift
    to prompt: Prompt,
    schema: GenerationSchema,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions()
```
) -> sending LanguageModelSession.ResponseStream<GeneratedContent>
Show all declarations


## Parameters

prompt
A prompt for the model to respond to.
schema
A schema to guide the output with.
includeSchemaInPrompt
Inject the schema into the prompt to bias the model.
options
Options that control how tokens are sampled from the distribution the model produces.

## Return Value

A response stream that produces GeneratedContent containing the fields and values defined in the schema.

## Discussion

Consider using the default value of true for includeSchemaInPrompt. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.
Important
If running in the background, use the non-streaming respond(to:options:) method to reduce the likelihood of encountering LanguageModelSession.GenerationError.rateLimited(_:) errors.

## See Also

Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.



## Instance Method

streamResponse(options:prompt:)
Produces a response stream to a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final func streamResponse(

```swift
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
```
) rethrows -> sending LanguageModelSession.ResponseStream<String>

## Parameters

options
GenerationOptions that control how tokens are sampled from the distribution the model produces.
prompt
A specific prompt for the model to respond to.

## Return Value

A response stream that produces aggregated tokens.

## Discussion

Important
If running in the background, use the non-streaming respond(to:options:) method to reduce the likelihood of encountering LanguageModelSession.GenerationError.rateLimited(_:) errors.

## See Also

Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.



## Instance Method

streamResponse(generating:includeSchemaInPrompt:options:prompt:)
Produces a response stream for a type.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final func streamResponse<Content>(

```swift
    generating type: Content.Type = Content.self,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
```
) rethrows -> sending LanguageModelSession.ResponseStream<Content> where Content : Generable

## Parameters

type
A type to produce as the response.
includeSchemaInPrompt
Inject the schema into the prompt to bias the model.
options
Options that control how tokens are sampled from the distribution the model produces.
prompt
A prompt for the model to respond to.

## Return Value

A response stream.

## Mentioned in


Analyzing the runtime performance of your Foundation Models app

## Discussion

Consider using the default value of true for includeSchemaInPrompt. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.
Important
If running in the background, use the non-streaming respond(to:options:) method to reduce the likelihood of encountering LanguageModelSession.GenerationError.rateLimited(_:) errors.

## See Also

Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.



## Instance Method

streamResponse(schema:includeSchemaInPrompt:options:prompt:)
Produces a response stream to a prompt and schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
final func streamResponse(

```swift
    schema: GenerationSchema,
    includeSchemaInPrompt: Bool = true,
    options: GenerationOptions = GenerationOptions(),
    @PromptBuilder prompt: () throws -> Prompt
```
) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>

## Parameters

schema
A schema to guide the output with.
includeSchemaInPrompt
Inject the schema into the prompt to bias the model.
options
Options that control how tokens are sampled from the distribution the model produces.
prompt
A prompt for the model to respond to.

## Return Value

A response stream that produces GeneratedContent containing the fields and values defined in the schema.

## Discussion

Consider using the default value of true for includeSchemaInPrompt. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.
Important
If running in the background, use the non-streaming respond(to:options:) method to reduce the likelihood of encountering LanguageModelSession.GenerationError.rateLimited(_:) errors.

## See Also

Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.



# Structure

LanguageModelSession.ResponseStream
An async sequence of snapshots of partially generated content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ResponseStream<Content> where Content : Generable
```

## Topics

Collecting the response stream

```swift
func collect() async throws -> sending LanguageModelSession.Response<Content>
```
The result from a streaming response, after it completes.
Getting a snapshot of a partial response

```swift
struct Snapshot
```
A snapshot of partially generated content.

## Relationships


## Conforms To

- AsyncSequence
- Copyable

## See Also

Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.



## Instance Method

collect()
The result from a streaming response, after it completes.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
nonisolated(nonsending)

```swift
func collect() async throws -> sending LanguageModelSession.Response<Content>
```
Available when Content conforms to Generable.

## Discussion

If the streaming response was finished successfully before calling collect(), this method Response returns immediately.
If the streaming response was finished with an error before calling collect(), this method propagates that error.



# Structure

LanguageModelSession.ResponseStream.Snapshot
A snapshot of partially generated content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Snapshot
```

## Topics

Instance Properties

```swift
var content: Content.PartiallyGenerated
```
The content of the response.

```swift
var rawContent: GeneratedContent
```
The raw content of the response.



## Instance Property

content
The content of the response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var content: Content.PartiallyGenerated
```

## See Also

Instance Properties

```swift
var rawContent: GeneratedContent
```
The raw content of the response.


nstance Property
rawContent
The raw content of the response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var rawContent: GeneratedContent
```

## Discussion

When Content is GeneratedContent, this is the same as content.

## See Also

Instance Properties

```swift
var content: Content.PartiallyGenerated
```
The content of the response.



# Structure

GeneratedContent
A type that represents structured, generated content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct GeneratedContent
```

## Mentioned in


Expanding generation with tool calling

Generating Swift data structures with guided generation

## Overview

Generated content may contain a single value, an array, or key-value pairs with unique keys.

## Topics

Creating generated content

```swift
init(_:)
```
Creates generated content from another value.

```swift
init(some ConvertibleToGeneratedContent, id: GenerationID)
```
Creates content that contains a single value with a custom GenerationID.

```swift
init<S>(elements: S, id: GenerationID?)
```
Creates content representing an array of elements you specify.

```swift
init(kind: GeneratedContent.Kind, id: GenerationID?)
```
Creates a new GeneratedContent instance with the specified kind and GenerationID.
Creating content from properties

```swift
init(properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>, id: GenerationID?)
```
Creates generated content representing a structure with the properties you specify.

```swift
init<S>(properties: S, id: GenerationID?, uniquingKeysWith: (GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent) rethrows
```
Creates new generated content from the key-value pairs in the given sequence, using a combining closure to determine the value for any duplicate keys.
Creating content from JSON

```swift
init(json: String) throws
```
Creates equivalent content from a JSON string.
Creating content from kind

```swift
init(kind: GeneratedContent.Kind, id: GenerationID?)
```
Creates a new GeneratedContent instance with the specified kind and GenerationID.

```swift
enum Kind
```
The representation of the generated content.
Accessing instance properties

```swift
var kind: GeneratedContent.Kind
```
The kind representation of this generated content.

```swift
var isComplete: Bool
```
A Boolean that indicates whether the generated content is completed.

```swift
var jsonString: String
```
Returns a JSON string representation of the generated content.
Getting the debug description

```swift
var debugDescription: String
```
A string representation for the debug description.
Reads a value from the concrete type

```swift
func value<Value>(Value.Type) throws -> Value
```
Reads a top level, concrete partially Generable type from a named property.

```swift
func value(_:forProperty:)
```
Reads a concrete Generable type from named property.
Retrieving the schema and content

```swift
var generatedContent: GeneratedContent
```
A representation of this instance.
Getting the unique generation id

```swift
var id: GenerationID?
```
A unique id that is stable for the duration of a generated response.

## Relationships


## Conforms To

- ConvertibleFromGeneratedContent
- ConvertibleToGeneratedContent
- CustomDebugStringConvertible
- Equatable
- Generable
- InstructionsRepresentable
- PromptRepresentable
- Sendable
- SendableMetatype

## See Also

Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.



## Initializer


```swift
init(_:)
```
Creates generated content from another value.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(_ content: GeneratedContent) throws
```
Show all declarations


## Discussion

This is used to satisfy Generable.init(_:).

## See Also

Creating generated content

```swift
init(some ConvertibleToGeneratedContent, id: GenerationID)
```
Creates content that contains a single value with a custom GenerationID.

```swift
init<S>(elements: S, id: GenerationID?)
```
Creates content representing an array of elements you specify.

```swift
init(kind: GeneratedContent.Kind, id: GenerationID?)
```
Creates a new GeneratedContent instance with the specified kind and GenerationID.


## Initializer


```swift
init(_:id:)
```
Creates content that contains a single value with a custom GenerationID.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    _ value: some ConvertibleToGeneratedContent,
    id: GenerationID
```
)

## Parameters

value
The underlying value.
id
The GenerationID for this content.

## See Also

Creating generated content

```swift
init(_:)
```
Creates generated content from another value.

```swift
init<S>(elements: S, id: GenerationID?)
```
Creates content representing an array of elements you specify.

```swift
init(kind: GeneratedContent.Kind, id: GenerationID?)
```
Creates a new GeneratedContent instance with the specified kind and GenerationID.


## Initializer


```swift
init(elements:id:)
```
Creates content representing an array of elements you specify.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init<S>(
    elements: S,
    id: GenerationID? = nil
```
) where S : Sequence, S.Element == any ConvertibleToGeneratedContent

## See Also

Creating generated content

```swift
init(_:)
```
Creates generated content from another value.

```swift
init(some ConvertibleToGeneratedContent, id: GenerationID)
```
Creates content that contains a single value with a custom GenerationID.

```swift
init(kind: GeneratedContent.Kind, id: GenerationID?)
```
Creates a new GeneratedContent instance with the specified kind and GenerationID.


## Initializer


```swift
init(kind:id:)
```
Creates a new GeneratedContent instance with the specified kind and GenerationID.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    kind: GeneratedContent.Kind,
    id: GenerationID? = nil
```
)

## Parameters

kind
The kind of content to create.
id
An optional GenerationID to associate with this content.

## Discussion

This initializer provides a convenient way to create content from its kind representation.

## See Also

Creating generated content

```swift
init(_:)
```
Creates generated content from another value.

```swift
init(some ConvertibleToGeneratedContent, id: GenerationID)
```
Creates content that contains a single value with a custom GenerationID.

```swift
init<S>(elements: S, id: GenerationID?)
```
Creates content representing an array of elements you specify.


## Initializer


```swift
init(properties:id:)
```
Creates generated content representing a structure with the properties you specify.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>,
    id: GenerationID? = nil
```
)

## Discussion

The order of properties is important. For Generable types, the order must match the order properties in the types schema.

## See Also

Creating content from properties

```swift
init<S>(properties: S, id: GenerationID?, uniquingKeysWith: (GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent) rethrows
```
Creates new generated content from the key-value pairs in the given sequence, using a combining closure to determine the value for any duplicate keys.



## Initializer


```swift
init(properties:id:uniquingKeysWith:)
```
Creates new generated content from the key-value pairs in the given sequence, using a combining closure to determine the value for any duplicate keys.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init<S>(
    properties: S,
    id: GenerationID? = nil,
    uniquingKeysWith combine: (GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent
```
) rethrows where S : Sequence, S.Element == (String, any ConvertibleToGeneratedContent)

## Parameters

properties
A sequence of key-value pairs to use for the new content.
id
A unique id associated with GeneratedContent.
combine
A closure that is called with the values to resolve any duplicates keys that are encountered. The closure returns the desired value for the final content.

## Discussion

The order of properties is important. For Generable types, the order must match the order properties in the types schema.
You use this initializer to create generated content when you have a sequence of key-value tuples that might have duplicate keys. As the content is built, the initializer calls the combine closure with the current and new values for any duplicate keys. Pass a closure as combine that returns the value to use in the resulting content: The closure can choose between the two values, combine them to produce a new value, or even throw an error.
The following example shows how to choose the first and last values for any duplicate keys:

```swift
    let content = GeneratedContent(
      properties: [("name", "John"), ("name", "Jane"), ("married", true)],
      uniquingKeysWith: { (first, _) in first }
    )
    // GeneratedContent(["name": "John", "married": true])
```

## See Also

Creating content from properties

```swift
init(properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>, id: GenerationID?)
```
Creates generated content representing a structure with the properties you specify.



## Initializer


```swift
init(json:)
```
Creates equivalent content from a JSON string.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(json: String) throws
```

## Discussion

The JSON string you provide may be incomplete. This is useful for correctly handling partially generated responses.

```swift
@Generable struct NovelIdea {
  let title: String
}


let partial = #"{"title": "A story of"#
let content = try GeneratedContent(json: partial)
let idea = try NovelIdea(content)
```
print(idea.title) // A story of



## Initializer


```swift
init(kind:id:)
```
Creates a new GeneratedContent instance with the specified kind and GenerationID.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    kind: GeneratedContent.Kind,
    id: GenerationID? = nil
```
)

## Parameters

kind
The kind of content to create.
id
An optional GenerationID to associate with this content.

## Discussion

This initializer provides a convenient way to create content from its kind representation.

## See Also

Creating generated content

```swift
init(_:)
```
Creates generated content from another value.

```swift
init(some ConvertibleToGeneratedContent, id: GenerationID)
```
Creates content that contains a single value with a custom GenerationID.

```swift
init<S>(elements: S, id: GenerationID?)
```
Creates content representing an array of elements you specify.



# Enumeration

GeneratedContent.Kind
The representation of the generated content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum Kind
```

## Overview

This property provides access to the content in a strongly-typed enumeration representation, preserving the hierarchical structure of the data and the data’s GenerationID values.

## Topics

Getting the kind of content

```swift
case array([GeneratedContent])
```
Represents an array of GeneratedContent elements.

```swift
case bool(Bool)
```
Represents a boolean value.

```swift
case null
```
Represents a null value.

```swift
case number(Double)
```
Represents a numeric value.

```swift
case string(String)
```
Represents a string value.

```swift
case structure(properties: [String : GeneratedContent], orderedKeys: [String])
```
Represents a structured object with key-value pairs.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Creating content from kind

```swift
init(kind: GeneratedContent.Kind, id: GenerationID?)
```
Creates a new GeneratedContent instance with the specified kind and GenerationID.


Case
GeneratedContent.Kind.array(_:)
Represents an array of GeneratedContent elements.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case array([GeneratedContent])
```

## Parameters

elements
An array of GeneratedContent instances.

## See Also

Getting the kind of content

```swift
case bool(Bool)
```
Represents a boolean value.

```swift
case null
```
Represents a null value.

```swift
case number(Double)
```
Represents a numeric value.

```swift
case string(String)
```
Represents a string value.

```swift
case structure(properties: [String : GeneratedContent], orderedKeys: [String])
```
Represents a structured object with key-value pairs.


Case
GeneratedContent.Kind.bool(_:)
Represents a boolean value.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case bool(Bool)
```

## Parameters

value
The boolean value.

## See Also

Getting the kind of content

```swift
case array([GeneratedContent])
```
Represents an array of GeneratedContent elements.

```swift
case null
```
Represents a null value.

```swift
case number(Double)
```
Represents a numeric value.

```swift
case string(String)
```
Represents a string value.

```swift
case structure(properties: [String : GeneratedContent], orderedKeys: [String])
```
Represents a structured object with key-value pairs.


Case
GeneratedContent.Kind.null
Represents a null value.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case null
```

## See Also

Getting the kind of content

```swift
case array([GeneratedContent])
```
Represents an array of GeneratedContent elements.

```swift
case bool(Bool)
```
Represents a boolean value.

```swift
case number(Double)
```
Represents a numeric value.

```swift
case string(String)
```
Represents a string value.

```swift
case structure(properties: [String : GeneratedContent], orderedKeys: [String])
```
Represents a structured object with key-value pairs.


Case
GeneratedContent.Kind.number(_:)
Represents a numeric value.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case number(Double)
```

## Parameters

value
The numeric value as a Double.

## See Also

Getting the kind of content

```swift
case array([GeneratedContent])
```
Represents an array of GeneratedContent elements.

```swift
case bool(Bool)
```
Represents a boolean value.

```swift
case null
```
Represents a null value.

```swift
case string(String)
```
Represents a string value.

```swift
case structure(properties: [String : GeneratedContent], orderedKeys: [String])
```
Represents a structured object with key-value pairs.


Case
GeneratedContent.Kind.string(_:)
Represents a string value.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case string(String)
```

## Parameters

value
The string value.

## See Also

Getting the kind of content

```swift
case array([GeneratedContent])
```
Represents an array of GeneratedContent elements.

```swift
case bool(Bool)
```
Represents a boolean value.

```swift
case null
```
Represents a null value.

```swift
case number(Double)
```
Represents a numeric value.

```swift
case structure(properties: [String : GeneratedContent], orderedKeys: [String])
```
Represents a structured object with key-value pairs.


Case
GeneratedContent.Kind.structure(properties:orderedKeys:)
Represents a structured object with key-value pairs.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case structure(
    properties: [String : GeneratedContent],
    orderedKeys: [String]
```
)

## Parameters

properties
A dictionary mapping string keys to GeneratedContent values.
orderedKeys
An array of keys that specifies the order of properties.

## See Also

Getting the kind of content

```swift
case array([GeneratedContent])
```
Represents an array of GeneratedContent elements.

```swift
case bool(Bool)
```
Represents a boolean value.

```swift
case null
```
Represents a null value.

```swift
case number(Double)
```
Represents a numeric value.

```swift
case string(String)
```
Represents a string value.



## Instance Property

kind
The kind representation of this generated content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var kind: GeneratedContent.Kind { get }
```

## Discussion

This property provides access to the content in a strongly-typed enum representation, preserving the hierarchical structure of the data and the data’s GenerationID ids.

## See Also

Accessing instance properties

```swift
var isComplete: Bool
```
A Boolean that indicates whether the generated content is completed.

```swift
var jsonString: String
```
Returns a JSON string representation of the generated content.



## Instance Property

isComplete
A Boolean that indicates whether the generated content is completed.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var isComplete: Bool { get }
```

## See Also

Accessing instance properties

```swift
var kind: GeneratedContent.Kind
```
The kind representation of this generated content.

```swift
var jsonString: String
```
Returns a JSON string representation of the generated content.



## Instance Property

jsonString
Returns a JSON string representation of the generated content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var jsonString: String { get }
```
Examples
// Object with properties

```swift
let content = GeneratedContent(properties: [
    "name": "Johnny Appleseed",
    "age": 30,
```
])
print(content.jsonString)

```swift
// Output: {"name": "Johnny Appleseed", "age": 30}
```

## See Also

Accessing instance properties

```swift
var kind: GeneratedContent.Kind
```
The kind representation of this generated content.

```swift
var isComplete: Bool
```
A Boolean that indicates whether the generated content is completed.



## Instance Property

debugDescription
A string representation for the debug description.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var debugDescription: String { get }


```

## Instance Method

value(_:)
Reads a top level, concrete partially Generable type from a named property.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
func value<Value>(_ type: Value.Type = Value.self) throws -> Value where Value : ConvertibleFromGeneratedContent
```

## See Also

Reads a value from the concrete type

```swift
func value(_:forProperty:)
```
Reads a concrete Generable type from named property.



## Instance Method

value(_:forProperty:)
Reads a concrete Generable type from named property.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
func value<Value>(
    _ type: Value.Type = Value.self,
    forProperty property: String
```
) throws -> Value where Value : ConvertibleFromGeneratedContent
Show all declarations


## See Also

Reads a value from the concrete type

```swift
func value<Value>(Value.Type) throws -> Value
```
Reads a top level, concrete partially Generable type from a named property.



## Instance Property

generatedContent
A representation of this instance.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var generatedContent: GeneratedContent { get }


```

## Instance Property

id
A unique id that is stable for the duration of a generated response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var id: GenerationID?
```

## Discussion

A LanguageModelSession produces instances of GeneratedContent that have a non-nil id. When you stream a response, the id is the same for all partial generations in the response stream.
Instances of GeneratedContent that you produce manually with initializers have a nil id because the framework didn’t create them as part of a generation.



# Protocol

ConvertibleFromGeneratedContent
A type that can be initialized from generated content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
protocol ConvertibleFromGeneratedContent : SendableMetatype
```

## Topics

Creating a convertable

```swift
init(GeneratedContent) throws
```
Creates an instance from content generated by a model.
Required

## Relationships

Inherits From
- SendableMetatype

## Inherited By

- Generable

## Conforming Types

- GeneratedContent

## See Also

Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleToGeneratedContent
```
A type that can be converted to generated content.



## Initializer


```swift
init(_:)
```
Creates an instance from content generated by a model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(_ content: GeneratedContent) throws
```
Required

## Discussion

Conformance to this protocol is provided by the @Generable macro. A manual implementation may be used to map values onto properties using different names. To manually initialize your type from generated content, decode the values as shown below:

```swift
struct Person: ConvertibleFromGeneratedContent {
    var name: String
    var age: Int


    init(_ content: GeneratedContent) {
        self.name = try content.value(forProperty: "firstName")
        self.age = try content.value(forProperty: "ageInYears")
    }
}
```
Important
If your type also conforms to ConvertibleToGeneratedContent, it is critical that this implementation be symmetrical with generatedContent.

## See Also


```swift
@Generable macro Generable(description:)


```

# Protocol

ConvertibleToGeneratedContent
A type that can be converted to generated content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
protocol ConvertibleToGeneratedContent : InstructionsRepresentable, PromptRepresentable
```

## Topics

Getting the generated content

```swift
var generatedContent: GeneratedContent
```
This instance represented as generated content.
Required

## Relationships

Inherits From
- InstructionsRepresentable
- PromptRepresentable

## Inherited By

- Generable

## Conforming Types

- GeneratedContent

## See Also

Streaming a response

```swift
func streamResponse(to:options:)
```
Produces a response stream to a prompt.

```swift
func streamResponse(to:generating:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(to:schema:includeSchemaInPrompt:options:)
```
Produces a response stream to a prompt and schema.

```swift
func streamResponse(options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<String>
```
Produces a response stream to a prompt.

```swift
func streamResponse<Content>(generating: Content.Type, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<Content>
```
Produces a response stream for a type.

```swift
func streamResponse(schema: GenerationSchema, includeSchemaInPrompt: Bool, options: GenerationOptions, prompt: () throws -> Prompt) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent>
```
Produces a response stream to a prompt and schema.

```swift
struct ResponseStream
```
An async sequence of snapshots of partially generated content.

```swift
struct GeneratedContent
```
A type that represents structured, generated content.

```swift
protocol ConvertibleFromGeneratedContent
```
A type that can be initialized from generated content.



## Instance Property

generatedContent
This instance represented as generated content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var generatedContent: GeneratedContent { get }
```
Required

## Discussion

Conformance to this protocol is provided by the @Generable macro. A manual implementation may be used to map values onto properties using different names. Use the generated content property as shown below, to manually return a new GeneratedContent with the properties you specify.

```swift
struct Person: ConvertibleToGeneratedContent {
   var name: String
   var age: Int


   var generatedContent: GeneratedContent {
       GeneratedContent(properties: [
           "firstName": name,
           "ageInYears": age
       ])
   }
}
```
Important
If your type also conforms to ConvertibleFromGeneratedContent, it is critical that this implementation be symmetrical with init(_:).



## Instance Method

logFeedbackAttachment(sentiment:issues:desiredOutput:)
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@discardableResult
final func logFeedbackAttachment(

```swift
    sentiment: LanguageModelFeedback.Sentiment?,
    issues: [LanguageModelFeedback.Issue] = [],
    desiredOutput: Transcript.Entry? = nil
```
) -> Data

## Parameters

sentiment
A LanguageModelFeedback.Sentiment rating about the model’s output (positive, negative, or neutral).
issues
An array of specific LanguageModelFeedback.Issue you identify with the model’s response.
desiredOutput
A Transcript entry showing the output you expect.

## Return Value

A Data object containing the JSON-encoded attachment.

## Mentioned in


Prompting an on-device foundation model

## Discussion

This method creates a structured attachment containing the session’s transcript and additional feedback information you provide. You can save the attachment data to a .json file and attach it when reporting feedback with Feedback Assistant.
If an error occurs during a previous response, the method includes any rejected entries that were rolled back from the transcript in the feedback data.

```swift
let session = LanguageModelSession()
let response = try await session.respond(to: "What is the capital of France?")


```
// Create feedback for a helpful response.

```swift
let helpfulFeedbackData = session.logFeedbackAttachment(sentiment: .positive)


```
// Create feedback for a problematic response.

```swift
let problematicFeedbackData = session.logFeedbackAttachment(
    sentiment: .negative,
    issues: [
        LanguageModelFeedback.Issue(
            category: .incorrect,
            explanation: "The model provided outdated information"
        )
    ],
    desiredOutput: Transcript.Entry.response(...)
```
)
If desiredOutput is a string, use Transcript.Entry.response(_:) to turn your desired output into a Transcript entry:

```swift
let text = Transcript.TextSegment(content: "The capital of France is Paris.")
let segment = Transcript.Segment.text(text)
let response = Transcript.Response(segments: [segment])
let entry = Transcript.Entry.response(response)
```
To create a transcript when desiredOutput is a Generable type:

```swift
let customType = MyCustomType(...) // A generable type.
let structure = Transcript.StructuredSegment(source: String(describing: Foo.self), content: customType.generatedContent)
let segment = Transcript.Segment.structure(structure)
let response = Transcript.Response(segments: [segment])
let entry = Transcript.Entry.response(response)
```
When you submit feedback to Apple, write your feedback to a .json file and include the file as an attachment to Feedback Assistant. You can include multiple feedback attachments in the same file:

```swift
let allFeedback = helpfulFeedbackData + problematicFeedbackData
let url = URL(fileURLWithPath: "path/to/save/feedback.jsonl")
```
try allFeedback.write(to: url)

## See Also

Creating feedback

```swift
struct Issue
```
An issue with the model’s response.

```swift
enum Sentiment
```
A sentiment regarding the model’s response.



## Instance Method

logFeedbackAttachment(sentiment:issues:desiredResponseContent:)
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@backDeployed(before: iOS 26.1, macOS 26.1, visionOS 26.1)
@discardableResult
final func logFeedbackAttachment(

```swift
    sentiment: LanguageModelFeedback.Sentiment?,
    issues: [LanguageModelFeedback.Issue] = [],
    desiredResponseContent: (any ConvertibleToGeneratedContent)?
```
) -> Data

## See Also

Generating feedback

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data
```
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredResponseText: String?) -> Data


```

## Instance Method

logFeedbackAttachment(sentiment:issues:desiredResponseText:)
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@backDeployed(before: iOS 26.1, macOS 26.1, visionOS 26.1)
@discardableResult
final func logFeedbackAttachment(

```swift
    sentiment: LanguageModelFeedback.Sentiment?,
    issues: [LanguageModelFeedback.Issue] = [],
    desiredResponseText: String?
```
) -> Data

## See Also

Generating feedback

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data
```
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredResponseContent: (any ConvertibleToGeneratedContent)?) -> Data


```

# Enumeration

LanguageModelSession.GenerationError
An error that may occur while generating a response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum GenerationError
```

## Topics

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.
Getting the error description

```swift
var errorDescription: String?
```
A string representation of the error description.
Getting the failure reason

```swift
var failureReason: String?
```
A string representation of the failure reason.
Getting the recovery suggestion

```swift
var recoverySuggestion: String?
```
A string representation of the recovery suggestion.

## Relationships


## Conforms To

- Error
- LocalizedError
- Sendable
- SendableMetatype

## See Also

Getting the error types

```swift
struct ToolCallError
```
An error that occurs while a system language model is calling a tool.


Case
LanguageModelSession.GenerationError.assetsUnavailable(_:)
An error that indicates the assets required for the session are unavailable.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```

## Discussion

This may happen if you forget to check model availability to begin with, or if the model assets are deleted. This can happen if the user disables AppleIntelligence while your app is running.
You may be able to recover from this error by retrying later after the device has freed up enough space to redownload model assets.

## See Also

Generation errors

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.


Case
LanguageModelSession.GenerationError.decodingFailure(_:)
An error that indicates the session failed to deserialize a valid generable type from model output.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```

## Discussion

This can happen if generation was terminated early.

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.


Case
LanguageModelSession.GenerationError.exceededContextWindowSize(_:)
An error that signals the session reached its context window size limit.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```

## Mentioned in


Analyzing the runtime performance of your Foundation Models app

Generating content and performing tasks with Foundation Models

## Discussion

This error occurs when you use the available tokens for the context window of 4,096 tokens. The token count includes instructions, prompts, and outputs for a session instance. A single token corresponds to approximately three to four characters in languages like English, Spanish, or German, and one token per character in languages like Japanese, Chinese, and Korean.
Start a new session when you exceed the content window size, and try again using a shorter prompt or shorter output length.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.


Case
LanguageModelSession.GenerationError.guardrailViolation(_:)
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```

## Mentioned in


Improving the safety of generative model output

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.


Case
LanguageModelSession.GenerationError.rateLimited(_:)
An error that indicates your session has been rate limited.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```

## Discussion

This error will only happen if your app is running in the background and exceeds the system defined rate limit.

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.


Case
LanguageModelSession.GenerationError.refusal(_:_:)
An error that happens when the session refuses the request.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```

## Mentioned in


Improving the safety of generative model output

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.


Case
LanguageModelSession.GenerationError.concurrentRequests(_:)
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.


Case
LanguageModelSession.GenerationError.unsupportedGuide(_:)
An error that indicates a generation guide with an unsupported pattern was used.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.


Case
LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(_:)
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```

## Mentioned in


Supporting languages and locales with Foundation Models

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
struct Context
```
The context in which the error occurred.

```swift
struct Refusal
```
A refusal produced by a language model.



# Structure

LanguageModelSession.GenerationError.Context
The context in which the error occurred.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Context
```

## Topics

Creating a context

```swift
init(debugDescription: String)
```
Creates a context.
Getting the debug description

```swift
let debugDescription: String
```
A debug description to help developers diagnose issues during development.

## Relationships


## Conforms To

- Sendable
- SendableMetatype

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Refusal
```
A refusal produced by a language model.



## Initializer


```swift
init(debugDescription:)
```
Creates a context.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(debugDescription: String)
```

## Parameters

debugDescription
The debug description to help developers diagnose issues during development.



## Instance Property

debugDescription
A debug description to help developers diagnose issues during development.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
let debugDescription: String
```

## Discussion

This string is not localized and is not appropriate for display to end users.



# Structure

LanguageModelSession.GenerationError.Refusal
A refusal produced by a language model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Refusal
```

## Overview

Refusal errors indicate that the model chose not to respond to a prompt. To make the model explain why it refused, catch the refusal error and access one of its explanation properties.

```swift
do {
    let session = LanguageModelSession()
    let response = try await session.respond(to: "...", 
                                             generating: MyGenerableStruct.self)
} catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
    let message = try await refusal.explanation
    print(message)
} catch {
    print("Something went wrong: \(error)")
}
```
Note
Refusal errors can only be caught when you use guided generation.

## Topics

Creating a generation error refusal

```swift
init(transcriptEntries: [Transcript.Entry])
```
Getting the explanation

```swift
var explanation: LanguageModelSession.Response<String>
```
An explanation for why the model refused to respond.

```swift
var explanationStream: LanguageModelSession.ResponseStream<String>
```
A stream containing an explanation about why the model refused to respond.

## Relationships


## Conforms To

- Sendable
- SendableMetatype

## See Also

Generation errors

```swift
case assetsUnavailable(LanguageModelSession.GenerationError.Context)
```
An error that indicates the assets required for the session are unavailable.

```swift
case decodingFailure(LanguageModelSession.GenerationError.Context)
```
An error that indicates the session failed to deserialize a valid generable type from model output.

```swift
case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)
```
An error that signals the session reached its context window size limit.

```swift
case guardrailViolation(LanguageModelSession.GenerationError.Context)
```
An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

```swift
case rateLimited(LanguageModelSession.GenerationError.Context)
```
An error that indicates your session has been rate limited.

```swift
case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)
```
An error that happens when the session refuses the request.

```swift
case concurrentRequests(LanguageModelSession.GenerationError.Context)
```
An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

```swift
case unsupportedGuide(LanguageModelSession.GenerationError.Context)
```
An error that indicates a generation guide with an unsupported pattern was used.

```swift
case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)
```
An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

```swift
struct Context
```
The context in which the error occurred.



## Initializer


```swift
init(transcriptEntries:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(transcriptEntries: [Transcript.Entry])

```

## Instance Property

explanation
An explanation for why the model refused to respond.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var explanation: LanguageModelSession.Response<String> { get async throws }
```

## See Also

Getting the explanation

```swift
var explanationStream: LanguageModelSession.ResponseStream<String>
```
A stream containing an explanation about why the model refused to respond.



## Instance Property

explanationStream
A stream containing an explanation about why the model refused to respond.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var explanationStream: LanguageModelSession.ResponseStream<String> { get }
```

## See Also

Getting the explanation

```swift
var explanation: LanguageModelSession.Response<String>
```
An explanation for why the model refused to respond.



## Instance Property

errorDescription
A string representation of the error description.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var errorDescription: String? { get }


```

## Instance Property

failureReason
A string representation of the failure reason.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var failureReason: String? { get }


```

## Instance Property

recoverySuggestion
A string representation of the recovery suggestion.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var recoverySuggestion: String? { get }


```

# Structure

LanguageModelSession.ToolCallError
An error that occurs while a system language model is calling a tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ToolCallError
```

## Mentioned in


Expanding generation with tool calling

## Topics

Creating a tool call error

```swift
init(tool: any Tool, underlyingError: any Error)
```
Creates a tool call error
Getting the tool

```swift
var tool: any Tool
```
The tool that produced the error.
Getting the error description

```swift
var errorDescription: String?
```
A string representation of the error description.
Getting the underlying error

```swift
var underlyingError: any Error
```
The underlying error that was thrown during a tool call.

## Relationships


## Conforms To

- Error
- LocalizedError
- Sendable
- SendableMetatype

## See Also

Getting the error types

```swift
enum GenerationError
```
An error that may occur while generating a response.



## Initializer


```swift
init(tool:underlyingError:)
```
Creates a tool call error
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    tool: any Tool,
    underlyingError: any Error
```
)

## Parameters

tool
The tool that produced the error.
underlyingError
The underlying error that was thrown during a tool call.



## Instance Property

tool
The tool that produced the error.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var tool: any Tool


```

## Instance Property

errorDescription
A string representation of the error description.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var errorDescription: String? { get }


```

## Instance Property

underlyingError
The underlying error that was thrown during a tool call.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var underlyingError: any Error


```

# Structure

Instructions
Details you provide that define the model’s intended behavior on prompts.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Instructions
```

## Mentioned in


Generating content and performing tasks with Foundation Models

Improving the safety of generative model output

Prompting an on-device foundation model

Supporting languages and locales with Foundation Models

## Overview

Instructions are typically provided by you to define the role and behavior of the model. In the code below, the instructions specify that the model replies with topics rather than, for example, a recipe:

```swift
let instructions = """
    Suggest related topics. Keep them concise (three to seven words) and make sure they \
    build naturally from the person's topic.
    """


let session = LanguageModelSession(instructions: instructions)


let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)
```
Apple trains the model to obey instructions over any commands it receives in prompts, so don’t include untrusted content in instructions. For more on how instructions impact generation quality and safety, see Improving the safety of generative model output.
All input to the model contributes tokens to the context window of the LanguageModelSession — including the Instructions, Prompt, Tool, and Generable types, and the model’s responses. If your session exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:).
Instructions can consume a lot of tokens that contribute to the context window size. To reduce your instruction size:
- Write shorter instructions to save tokens.
- Provide only the information necessary to perform the task.
- Use concise and imperative language instead of indirect or jargon that the model might misinterpret.
- Aim for one to three paragraphs instead of including a significant amount of background information, policy, or extra content.
For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Creating instructions

```swift
init(_:)
struct InstructionsBuilder
```
A type that represents an instructions builder.

```swift
protocol InstructionsRepresentable
```
A type that can be represented as instructions.

## Relationships


## Conforms To

- Copyable
- InstructionsRepresentable
- Sendable
- SendableMetatype

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Initializer


```swift
init(_:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows
```
Show all declarations


## See Also

Creating instructions

```swift
struct InstructionsBuilder
```
A type that represents an instructions builder.

```swift
protocol InstructionsRepresentable
```
A type that can be represented as instructions.



# Structure

InstructionsBuilder
A type that represents an instructions builder.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@resultBuilder
struct InstructionsBuilder
```

## Topics

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.

## See Also

Creating instructions

```swift
init(_:)
protocol InstructionsRepresentable
```
A type that can be represented as instructions.


## Type Method

buildArray(_:)
Creates a builder with the an array of prompts.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildArray(_ instructions: [some InstructionsRepresentable]) -> Instructions

## See Also

Building instructions
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.


## Type Method

buildBlock(_:)
Creates a builder with the a block.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildBlock<each I>(_ components: repeat each I) -> Instructions where repeat each I : InstructionsRepresentable

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildEither(first:)
Creates a builder with the first component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildEither(first component: some InstructionsRepresentable) -> Instructions

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildEither(second:)
Creates a builder with the second component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildEither(second component: some InstructionsRepresentable) -> Instructions

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildExpression(_:)
Creates a builder with a prompt expression.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildExpression(_ expression: Instructions) -> Instructions
Show all declarations


## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildLimitedAvailability(_:)
Creates a builder with a limited availability prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildLimitedAvailability(_ instructions: some InstructionsRepresentable) -> Instructions

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildOptional(Instructions?) -> Instructions
Creates a builder with an optional component.



## Type Method

buildOptional(_:)
Creates a builder with an optional component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildOptional(_ instructions: Instructions?) -> Instructions

## See Also

Building instructions
static func buildArray([some InstructionsRepresentable]) -> Instructions
Creates a builder with the an array of prompts.
static func buildBlock<each I>(repeat each I) -> Instructions
Creates a builder with the a block.
static func buildEither(first: some InstructionsRepresentable) -> Instructions
Creates a builder with the first component.
static func buildEither(second: some InstructionsRepresentable) -> Instructions
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions
Creates a builder with a limited availability prompt.



# Protocol

InstructionsRepresentable
A type that can be represented as instructions.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
protocol InstructionsRepresentable
```

## Topics

Getting the representation

```swift
var instructionsRepresentation: Instructions
```
An instance that represents the instructions.
Required Default implementation provided.

## Relationships


## Inherited By

- ConvertibleToGeneratedContent
- Generable

## Conforming Types

- GeneratedContent
- Instructions

## See Also

Creating instructions

```swift
init(_:)
struct InstructionsBuilder
```
A type that represents an instructions builder.



## Instance Property

instructionsRepresentation
An instance that represents the instructions.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@InstructionsBuilder
var instructionsRepresentation: Instructions { get }
```
Required Default implementation provided.

## Default Implementations

InstructionsRepresentable Implementations

```swift
var instructionsRepresentation: Instructions
```
An instance that represents the instructions.



# Structure

Prompt
A prompt from a person to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Prompt
```

## Mentioned in


Generating content and performing tasks with Foundation Models

Prompting an on-device foundation model

## Overview

Prompts can contain content written by you, an outside source, or input directly from people using your app. You can initialize a Prompt from a string literal:

```swift
let prompt = Prompt("What are miniature schnauzers known for?")
```
Use PromptBuilder to dynamically control the prompt’s content based on your app’s state. The code below shows that if the Boolean is true, the prompt includes a second line of text:

```swift
let responseShouldRhyme = true
let prompt = Prompt {
    "Answer the following question from the user: \(userInput)"
    if responseShouldRhyme {
        "Your response MUST rhyme!"
    }
}
```
If your prompt includes input from people, consider wrapping the input in a string template with your own prompt to better steer the model’s response. For more information on handling inputs in your prompts, see Improving the safety of generative model output.
All input to the model contributes tokens to the context window of the LanguageModelSession — including the Instructions, Prompt, Tool, and Generable types, and the model’s responses. If your session exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:).
Prompts can consume a lot of tokens, especially when you send multiple prompts to the same session. To reduce your prompt size when you exceed the context window size:
- Write shorter prompts to save tokens.
- Provide only the information necessary to perform the task.
- Use concise and imperative language instead of indirect or jargon that the model might misinterpret.
- Use a clear verb that tells the model what to do, like “Generate”, “List”, or “Summarize”.
- Include the target response length you want, like “In three sentences” or “List five reasons”.
Prompting the same session eventually leads to exceeding the context window size. When that happens, create a new context window by initializing a new instance of LanguageModelSession. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Creating a prompt

```swift
init(_:)
struct PromptBuilder
```
A type that represents a prompt builder.

```swift
protocol PromptRepresentable
```
A type whose value can represent a prompt.

## Relationships


## Conforms To

- Copyable
- PromptRepresentable
- Sendable
- SendableMetatype

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Initializer


```swift
init(_:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(@PromptBuilder _ content: () throws -> Prompt) rethrows
```
Show all declarations


## See Also

Creating a prompt

```swift
struct PromptBuilder
```
A type that represents a prompt builder.

```swift
protocol PromptRepresentable
```
A type whose value can represent a prompt.



# Structure

PromptBuilder
A type that represents a prompt builder.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@resultBuilder
struct PromptBuilder
```

## Topics

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.

## See Also

Creating a prompt

```swift
init(_:)
protocol PromptRepresentable
```
A type whose value can represent a prompt.



## Type Method

buildArray(_:)
Creates a builder with the an array of prompts.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt

## See Also

Building a prompt
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildBlock(_:)
Creates a builder with the a block.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P : PromptRepresentable

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildEither(first:)
Creates a builder with the first component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildEither(first component: some PromptRepresentable) -> Prompt

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildEither(second:)
Creates a builder with the second component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildEither(second component: some PromptRepresentable) -> Prompt

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildExpression(_:)
Creates a builder with a prompt expression.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildExpression(_ expression: Prompt) -> Prompt
Show all declarations


## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildLimitedAvailability(_:)
Creates a builder with a limited availability prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildLimitedAvailability(_ prompt: some PromptRepresentable) -> Prompt

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildOptional(Prompt?) -> Prompt
Creates a builder with an optional component.



## Type Method

buildOptional(_:)
Creates a builder with an optional component.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func buildOptional(_ component: Prompt?) -> Prompt

## See Also

Building a prompt
static func buildArray([some PromptRepresentable]) -> Prompt
Creates a builder with the an array of prompts.
static func buildBlock<each P>(repeat each P) -> Prompt
Creates a builder with the a block.
static func buildEither(first: some PromptRepresentable) -> Prompt
Creates a builder with the first component.
static func buildEither(second: some PromptRepresentable) -> Prompt
Creates a builder with the second component.
static buildExpression(_:)
Creates a builder with a prompt expression.
static func buildLimitedAvailability(some PromptRepresentable) -> Prompt
Creates a builder with a limited availability prompt.



# Protocol

PromptRepresentable
A type whose value can represent a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
protocol PromptRepresentable
```

## Overview

Important
Conformance to this protocol is provided automatically by the @Generable macro, you should not override its implementations. Overriding may negatively impact runtime performance and cause bugs.
For types that are not Generable, you may provide your own implementation.
Experiment with different representations to find one that works well for your type. Generally, any format that is easily understandable to humans will work well for the model as well.

```swift
struct FamousHistoricalFigure: PromptRepresentable {
    var name: String
    var biggestAccomplishment: String


    var promptRepresentation: Prompt {
        """
        Famous Historical Figure:
        - name: \(name)
        - best known for: \(biggestAccomplishment)
        """
    }
}


let response = try await LanguageModelSession().respond {
    "Tell me more about..."
    FamousHistoricalFigure(
        name: "Albert Einstein",
        biggestAccomplishment: "Theory of Relativity"
    )
}
```

## Topics

Getting the representation

```swift
var promptRepresentation: Prompt
```
An instance that represents a prompt.
Required Default implementation provided.

## Relationships


## Inherited By

- ConvertibleToGeneratedContent
- Generable

## Conforming Types

- GeneratedContent
- Prompt

## See Also

Creating a prompt

```swift
init(_:)
struct PromptBuilder
```
A type that represents a prompt builder.



## Instance Property

promptRepresentation
An instance that represents a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
@PromptBuilder
var promptRepresentation: Prompt { get }
```
Required Default implementation provided.

## Default Implementations

PromptRepresentable Implementations

```swift
var promptRepresentation: Prompt
```
An instance that represents a prompt.



# Structure

Transcript
A linear history of entries that reflect an interaction with a session.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Transcript
```

## Mentioned in


Generating content and performing tasks with Foundation Models

## Overview

Use a Transcript to visualize previous instructions, prompts and model responses. If you use tool calling, a Transcript includes a history of tool calls and their results.

```swift
struct HistoryView: View {
    let session: LanguageModelSession


    var body: some View {
        ScrollView {
            ForEach(session.transcript) { entry in
                switch entry {
                case let .instructions(instructions):
                    MyInstructionsView(instructions)
                case let .prompt(prompt)
                    MyPromptView(prompt)
                case let .toolCalls(toolCalls):
                    MyToolCallsView(toolCalls)
                case let .toolOutput(toolOutput):
                    MyToolOutputView(toolOutput)
                case let .response(response):
                    MyResponseView(response)
                }
            }
        }
    }
}
```
When you create a new LanguageModelSession it doesn’t contain the state of a previous session. You can initialize a new session with a list of entries you get from a session transcript:
// Create a new session with the first and last entries from a previous session.

```swift
func newContextualSession(with originalSession: LanguageModelSession) -> LanguageModelSession {
    let allEntries = originalSession.transcript


    // Collect the entries to keep from the original session.
    let entries = [allEntries.first, allEntries.last].compactMap { $0 }
    let transcript = Transcript(entries: entries)


    // Create a new session with the result and preload the session resources.
    var session = LanguageModelSession(transcript: transcript)
    session.prewarm()
    return session
}
```

## Topics

Creating a transcript

```swift
init(entries: some Sequence<Transcript.Entry>)
```
Creates a transcript.

```swift
enum Entry
```
An entry in a transcript.

```swift
enum Segment
```
The types of segments that may be included in a transcript entry.
Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.

## Relationships


## Conforms To

- BidirectionalCollection
- Collection
- Copyable
- Decodable
- Encodable
- Equatable
- RandomAccessCollection
- Sendable
- SendableMetatype
- Sequence

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct GenerationOptions
```
Options that control how the model generates its response to a prompt.



## Initializer


```swift
init(entries:)
```
Creates a transcript.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(entries: some Sequence<Transcript.Entry> = [])
```

## Parameters

entries
An array of entries to seed the transcript.

## See Also

Creating a transcript

```swift
enum Entry
```
An entry in a transcript.

```swift
enum Segment
```
The types of segments that may be included in a transcript entry.



# Enumeration

Transcript.Entry
An entry in a transcript.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum Entry
```

## Overview

An individual entry in a transcript may represent instructions from you to the model, a prompt from a user, tool calls, or a response generated by the model.

## Topics

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Creating a transcript

```swift
init(entries: some Sequence<Transcript.Entry>)
```
Creates a transcript.

```swift
enum Segment
```
The types of segments that may be included in a transcript entry.


Case
Transcript.Entry.instructions(_:)
Instructions, typically provided by you, the developer.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case instructions(Transcript.Instructions)
```

## See Also

Creating an entry

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.


Case
Transcript.Entry.prompt(_:)
A prompt, typically sourced from an end user.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case prompt(Transcript.Prompt)
```

## See Also

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.


Case
Transcript.Entry.response(_:)
A response from the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case response(Transcript.Response)
```

## See Also

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.


Case
Transcript.Entry.toolCalls(_:)
A tool call containing a tool name and the arguments to invoke it with.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case toolCalls(Transcript.ToolCalls)
```

## See Also

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolOutput(Transcript.ToolOutput)
```
An tool output provided back to the model.


Case
Transcript.Entry.toolOutput(_:)
An tool output provided back to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case toolOutput(Transcript.ToolOutput)
```

## See Also

Creating an entry

```swift
case instructions(Transcript.Instructions)
```
Instructions, typically provided by you, the developer.

```swift
case prompt(Transcript.Prompt)
```
A prompt, typically sourced from an end user.

```swift
case response(Transcript.Response)
```
A response from the model.

```swift
case toolCalls(Transcript.ToolCalls)
```
A tool call containing a tool name and the arguments to invoke it with.



# Enumeration

Transcript.Segment
The types of segments that may be included in a transcript entry.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum Segment
```

## Topics

Creating a segment

```swift
case structure(Transcript.StructuredSegment)
```
A segment containing structured content.

```swift
case text(Transcript.TextSegment)
```
A segment containing text.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Creating a transcript

```swift
init(entries: some Sequence<Transcript.Entry>)
```
Creates a transcript.

```swift
enum Entry
```
An entry in a transcript.


Case
Transcript.Segment.structure(_:)
A segment containing structured content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case structure(Transcript.StructuredSegment)
```

## See Also

Creating a segment

```swift
case text(Transcript.TextSegment)
```
A segment containing text.


Case
Transcript.Segment.text(_:)
A segment containing text.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case text(Transcript.TextSegment)
```

## See Also

Creating a segment

```swift
case structure(Transcript.StructuredSegment)
```
A segment containing structured content.



# Structure

Transcript.Instructions
Instructions you provide to the model that define its behavior.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Instructions
```

## Overview

Instructions are typically provided to define the role and behavior of the model. Apple trains the model to obey instructions over any commands it receives in prompts. This is a security mechanism to help mitigate prompt injection attacks.

## Topics

Creating instructions

```swift
init(id: String, segments: [Transcript.Segment], toolDefinitions: [Transcript.ToolDefinition])
```
Initialize instructions by describing how you want the model to behave using natural language.
Inspecting instructions

```swift
var segments: [Transcript.Segment]
```
The content of the instructions, in natural language.

```swift
var toolDefinitions: [Transcript.ToolDefinition]
```
A list of tools made available to the model.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:segments:toolDefinitions:)
```
Initialize instructions by describing how you want the model to behave using natural language.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    segments: [Transcript.Segment],
    toolDefinitions: [Transcript.ToolDefinition]
```
)

## Parameters

id
A unique identifier for this instructions segment.
segments
An array of segments that make up the instructions.
toolDefinitions
Tools that the model should be allowed to call.



## Instance Property

segments
The content of the instructions, in natural language.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var segments: [Transcript.Segment]
```

## Discussion

Note
Instructions are often provided in English even when the users interact with the model in another language.

## See Also

Inspecting instructions

```swift
var toolDefinitions: [Transcript.ToolDefinition]
```
A list of tools made available to the model.



## Instance Property

toolDefinitions
A list of tools made available to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var toolDefinitions: [Transcript.ToolDefinition]
```

## See Also

Inspecting instructions

```swift
var segments: [Transcript.Segment]
```
The content of the instructions, in natural language.


# Structure

Transcript.Prompt
A prompt from the user to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Prompt
```

## Overview

Prompts typically contain content sourced directly from the user, though you may choose to augment prompts by interpolating content from end users into a template that you control.

## Topics

Creating a prompt

```swift
init(id: String, segments: [Transcript.Segment], options: GenerationOptions, responseFormat: Transcript.ResponseFormat?)
```
Creates a prompt.
Inspecting a prompt

```swift
var id: String
```
The identifier of the prompt.

```swift
var responseFormat: Transcript.ResponseFormat?
```
An optional response format that describes the desired output structure.

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.

```swift
var options: GenerationOptions
```
Generation options associated with the prompt.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.


## Initializer


```swift
init(id:segments:options:responseFormat:)
```
Creates a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    segments: [Transcript.Segment],
    options: GenerationOptions = GenerationOptions(),
    responseFormat: Transcript.ResponseFormat? = nil
```
)

## Parameters

id
A Generable type to use as the response format.
segments
An array of segments that make up the prompt.
options
Options that control how tokens are sampled from the distribution the model produces.
responseFormat
A response format that describes the output structure.


## Instance Property

id
The identifier of the prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var id: String
```

## See Also

Inspecting a prompt

```swift
var responseFormat: Transcript.ResponseFormat?
```
An optional response format that describes the desired output structure.

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.

```swift
var options: GenerationOptions
```
Generation options associated with the prompt.


## Instance Property

responseFormat
An optional response format that describes the desired output structure.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var responseFormat: Transcript.ResponseFormat?
```

## See Also

Inspecting a prompt

```swift
var id: String
```
The identifier of the prompt.

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.

```swift
var options: GenerationOptions
```
Generation options associated with the prompt.



## Instance Property

segments
Ordered prompt segments.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var segments: [Transcript.Segment]
```

## See Also

Inspecting a prompt

```swift
var id: String
```
The identifier of the prompt.

```swift
var responseFormat: Transcript.ResponseFormat?
```
An optional response format that describes the desired output structure.

```swift
var options: GenerationOptions
```
Generation options associated with the prompt.



## Instance Property

options
Generation options associated with the prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var options: GenerationOptions
```

## See Also

Inspecting a prompt

```swift
var id: String
```
The identifier of the prompt.

```swift
var responseFormat: Transcript.ResponseFormat?
```
An optional response format that describes the desired output structure.

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.



# Structure

Transcript.Response
A response from the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Response
```

## Topics

Creating a response

```swift
init(id: String, assetIDs: [String], segments: [Transcript.Segment])
```
Inspecting a response

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.

```swift
var assetIDs: [String]
```
Version aware identifiers for all assets used to generate this response.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.


## Initializer


```swift
init(id:assetIDs:segments:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    assetIDs: [String],
    segments: [Transcript.Segment]
```
)

Current page is init(id:assetIDs:segments:)




## Instance Property

segments
Ordered prompt segments.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var segments: [Transcript.Segment]
```

## See Also

Inspecting a response

```swift
var assetIDs: [String]
```
Version aware identifiers for all assets used to generate this response.



## Instance Property

assetIDs
Version aware identifiers for all assets used to generate this response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var assetIDs: [String]
```

## See Also

Inspecting a response

```swift
var segments: [Transcript.Segment]
```
Ordered prompt segments.



# Structure

Transcript.ResponseFormat
Specifies a response format that the model must conform its output to.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ResponseFormat
```

## Topics

Creating a response format

```swift
init(schema: GenerationSchema)
```
Creates a response format with a schema.

```swift
init<Content>(type: Content.Type)
```
Creates a response format with type you specify.
Inspecting a response format

```swift
var name: String
```
A name associated with the response format.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(schema:)
```
Creates a response format with a schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(schema: GenerationSchema)
```

## Parameters

schema
A schema to use as the response format.

## See Also

Creating a response format

```swift
init<Content>(type: Content.Type)
```
Creates a response format with type you specify.



## Initializer


```swift
init(type:)
```
Creates a response format with type you specify.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init<Content>(type: Content.Type) where Content : Generable
```

## Parameters

type
A Generable type to use as the response format.

## See Also

Creating a response format

```swift
init(schema: GenerationSchema)
```
Creates a response format with a schema.



## Instance Property

name
A name associated with the response format.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var name: String { get }


```

# Structure

Transcript.StructuredSegment
A segment containing structured content.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct StructuredSegment
```

## Topics

Creating a structured segment

```swift
init(id: String, source: String, content: GeneratedContent)
```
Inspecting a structured segment

```swift
var content: GeneratedContent
```
The content of the segment.

```swift
var source: String
```
A source that be used to understand which type content represents.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:source:content:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    source: String,
    content: GeneratedContent
```
)



## Instance Property

content
The content of the segment.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var content: GeneratedContent { get set }
```

## See Also

Inspecting a structured segment

```swift
var source: String
```
A source that be used to understand which type content represents.



## Instance Property

source
A source that be used to understand which type content represents.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var source: String
```

## See Also

Inspecting a structured segment

```swift
var content: GeneratedContent
```
The content of the segment.



# Structure

Transcript.TextSegment
A segment containing text.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct TextSegment
```

## Topics

Creating a text segment

```swift
init(id: String, content: String)
```
Inspecting a text segment

```swift
var content: String
```

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:content:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String = UUID().uuidString,
    content: String
```
)



## Instance Property

content
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var content: String


```

# Structure

Transcript.ToolCall
A tool call generated by the model containing the name of a tool and arguments to pass to it.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ToolCall
```

## Topics

Creating a tool call

```swift
init(id: String, toolName: String, arguments: GeneratedContent)
```
Inspecting a tool call

```swift
var arguments: GeneratedContent
```
Arguments to pass to the invoked tool.

```swift
var toolName: String
```
The name of the tool being invoked.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:toolName:arguments:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String,
    toolName: String,
    arguments: GeneratedContent
```
)

Current page is init(id:toolName:arguments:)




## Instance Property

arguments
Arguments to pass to the invoked tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var arguments: GeneratedContent { get set }
```

## See Also

Inspecting a tool call

```swift
var toolName: String
```
The name of the tool being invoked.



## Instance Property

toolName
The name of the tool being invoked.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var toolName: String
```

## See Also

Inspecting a tool call

```swift
var arguments: GeneratedContent
```
Arguments to pass to the invoked tool.



# Structure

Transcript.ToolCalls
A collection tool calls generated by the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ToolCalls
```

## Topics

Creating a tool calls

```swift
init<S>(id: String, S)
```

## Relationships


## Conforms To

- BidirectionalCollection
- Collection
- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- RandomAccessCollection
- Sendable
- SendableMetatype
- Sequence

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolDefinition
```
A definition of a tool.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(id:_:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init<S>(
    id: String = UUID().uuidString,
    _ calls: S
```
) where S : Sequence, S.Element == Transcript.ToolCall



# Structure

Transcript.ToolDefinition
A definition of a tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ToolDefinition
```

## Topics

Creating a tool definition

```swift
init(name: String, description: String, parameters: GenerationSchema)
init(tool: some Tool)
```
Inspecting a tool definition

```swift
var description: String
```
A description of how and when to use the tool.

```swift
var name: String
```
The tool’s name.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolOutput
```
A tool output provided back to the model.



## Initializer


```swift
init(name:description:parameters:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    name: String,
    description: String,
    parameters: GenerationSchema
```
)

## See Also

Creating a tool definition

```swift
init(tool: some Tool)


```

## Initializer


```swift
init(tool:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(tool: some Tool)
```

## See Also

Creating a tool definition

```swift
init(name: String, description: String, parameters: GenerationSchema)


```

## Instance Property

description
A description of how and when to use the tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var description: String
```

## See Also

Inspecting a tool definition

```swift
var name: String
```
The tool’s name.



## Instance Property

name
The tool’s name.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var name: String
```

## See Also

Inspecting a tool definition

```swift
var description: String
```
A description of how and when to use the tool.



# Structure

Transcript.ToolOutput
A tool output provided back to the model.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct ToolOutput
```

## Topics

Creating a tool output

```swift
init(id: String, toolName: String, segments: [Transcript.Segment])
```
Inspecting a tool output

```swift
var id: String
```
A unique id for this tool output.

```swift
var segments: [Transcript.Segment]
```
Segments of the tool output.

```swift
var toolName: String
```
The name of the tool that produced this output.

## Relationships


## Conforms To

- Copyable
- CustomStringConvertible
- Equatable
- Identifiable
- Sendable
- SendableMetatype

## See Also

Getting the transcript types

```swift
struct Instructions
```
Instructions you provide to the model that define its behavior.

```swift
struct Prompt
```
A prompt from the user to the model.

```swift
struct Response
```
A response from the model.

```swift
struct ResponseFormat
```
Specifies a response format that the model must conform its output to.

```swift
struct StructuredSegment
```
A segment containing structured content.

```swift
struct TextSegment
```
A segment containing text.

```swift
struct ToolCall
```
A tool call generated by the model containing the name of a tool and arguments to pass to it.

```swift
struct ToolCalls
```
A collection tool calls generated by the model.

```swift
struct ToolDefinition
```
A definition of a tool.



## Initializer


```swift
init(id:toolName:segments:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    id: String,
    toolName: String,
    segments: [Transcript.Segment]
```
)



## Instance Property

id
A unique id for this tool output.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var id: String
```

## See Also

Inspecting a tool output

```swift
var segments: [Transcript.Segment]
```
Segments of the tool output.

```swift
var toolName: String
```
The name of the tool that produced this output.



## Instance Property

segments
Segments of the tool output.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var segments: [Transcript.Segment]
```

## See Also

Inspecting a tool output

```swift
var id: String
```
A unique id for this tool output.

```swift
var toolName: String
```
The name of the tool that produced this output.



## Instance Property

toolName
The name of the tool that produced this output.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var toolName: String
```

## See Also

Inspecting a tool output

```swift
var id: String
```
A unique id for this tool output.

```swift
var segments: [Transcript.Segment]
```
Segments of the tool output.



# Structure

GenerationOptions
Options that control how the model generates its response to a prompt.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct GenerationOptions
```

## Mentioned in


Generating content and performing tasks with Foundation Models

## Overview

Generation options determine the decoding strategy the framework uses to adjust the way the model chooses output tokens. When you interact with the model, it converts your input to a token sequence, and uses it to generate the response.
Only use maximumResponseTokens when you need to protect against unexpectedly verbose responses. Enforcing a strict token response limit can lead to the model producing malformed results or gramatically incorrect responses.
All input to the model contributes tokens to the context window of the LanguageModelSession — including the Instructions, Prompt, Tool, and Generable types, and the model’s responses. If your session exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:). For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Creating options

```swift
init(sampling: GenerationOptions.SamplingMode?, temperature: Double?, maximumResponseTokens: Int?)
```
Creates generation options that control token sampling behavior.
Configuring the response tokens

```swift
var maximumResponseTokens: Int?
```
The maximum number of tokens the model is allowed to produce in its response.
Configuring the sampling mode

```swift
var sampling: GenerationOptions.SamplingMode?
```
A sampling strategy for how the model picks tokens when generating a response.

```swift
struct SamplingMode
```
A type that defines how values are sampled from a probability distribution.
Configuring the temperature

```swift
var temperature: Double?
```
Temperature influences the confidence of the models response.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Prompting

Prompting an on-device foundation model
Tailor your prompts to get effective results from an on-device model.

Analyzing the runtime performance of your Foundation Models app
Optimize token consumption and improve response times by profiling your app’s model usage with Instruments.

```swift
class LanguageModelSession
```
An object that represents a session that interacts with a language model.

```swift
struct Instructions
```
Details you provide that define the model’s intended behavior on prompts.

```swift
struct Prompt
```
A prompt from a person to the model.

```swift
struct Transcript
```
A linear history of entries that reflect an interaction with a session.



## Initializer


```swift
init(sampling:temperature:maximumResponseTokens:)
```
Creates generation options that control token sampling behavior.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    sampling: GenerationOptions.SamplingMode? = nil,
    temperature: Double? = nil,
    maximumResponseTokens: Int? = nil
```
)

## Parameters

sampling
A strategy to use for sampling from a distribution.
temperature
Increasing temperature makes it possible for the model to produce less likely responses. Must be between 0 and 1, inclusive.
maximumResponseTokens
The maximum number of tokens the model is allowed to produce before being artificially halted. Must be positive.



## Instance Property

maximumResponseTokens
The maximum number of tokens the model is allowed to produce in its response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var maximumResponseTokens: Int?
```

## Discussion

If the model produce maximumResponseTokens before it naturally completes its response, the response will be terminated early. No error will be thrown. This property can be used to protect against unexpectedly verbose responses and runaway generations.
If no value is specified, then the model is allowed to produce the longest answer its context size supports. If the response exceeds that limit without terminating, an error will be thrown.



## Instance Property

sampling
A sampling strategy for how the model picks tokens when generating a response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var sampling: GenerationOptions.SamplingMode?
```

## Discussion

When you execute a prompt on a model, the model produces a probability for every token in its vocabulary. The sampling strategy controls how the model narrows down the list of tokens to consider during that process. A strategy that picks the single most likely token yields a predictable response every time, but other strategies offer results that often sound more natural to a person.
Note
Leaving the sampling nil lets the system choose a a reasonable default on your behalf.

## See Also

Configuring the sampling mode

```swift
struct SamplingMode
```
A type that defines how values are sampled from a probability distribution.


# Structure

GenerationOptions.SamplingMode
A type that defines how values are sampled from a probability distribution.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct SamplingMode
```

## Overview

A model builds its response to a prompt in a loop. At each iteration in the loop the model produces a probability distribution for all the tokens in its vocabulary. The sampling mode controls how a token is selected from that distribution.

## Topics

Sampling options
static var greedy: GenerationOptions.SamplingMode
A sampling mode that always chooses the most likely token.
static func random(probabilityThreshold: Double, seed: UInt64?) -> GenerationOptions.SamplingMode
A mode that considers a variable number of high-probability tokens based on the specified threshold.
static func random(top: Int, seed: UInt64?) -> GenerationOptions.SamplingMode
A sampling mode that considers a fixed number of high-probability tokens.

## Relationships


## Conforms To

- Equatable
- Sendable
- SendableMetatype

## See Also

Configuring the sampling mode

```swift
var sampling: GenerationOptions.SamplingMode?
```
A sampling strategy for how the model picks tokens when generating a response.



## Type Property

greedy
A sampling mode that always chooses the most likely token.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static var greedy: GenerationOptions.SamplingMode { get }
```

## Discussion

Using this mode will always result in the same output for a given input. Responses produced with greedy sampling are statistically likely, but may lack the human-like quality and variety of other sampling strategies.

## See Also

Sampling modes random(top:seed:) and random(probabilityThreshold:seed:)

## See Also

Sampling options
static func random(probabilityThreshold: Double, seed: UInt64?) -> GenerationOptions.SamplingMode
A mode that considers a variable number of high-probability tokens based on the specified threshold.
static func random(top: Int, seed: UInt64?) -> GenerationOptions.SamplingMode
A sampling mode that considers a fixed number of high-probability tokens.



## Type Method

random(probabilityThreshold:seed:)
A mode that considers a variable number of high-probability tokens based on the specified threshold.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func random(

```swift
    probabilityThreshold: Double,
    seed: UInt64? = nil
```
) -> GenerationOptions.SamplingMode

## Parameters

probabilityThreshold
A number between 0.0 and 1.0 that increases sampling pool size.
seed
An optional random seed used to make output more deterministic.

## Discussion

Also known as top-p or nucleus sampling.
With nucleus sampling, tokens are sorted by probability and added to a pool of candidates until the cumulative probability of the pool exceeds the specified threshold, and then a token is sampled from the pool.
Because the number of tokens isn’t predetermined, the selection pool size will be larger when the distribution is flat and smaller when it is spikey. This variability can lead to a wider variety of options to choose from, and potentially more creative responses.
Note
Setting a random seed is not guaranteed to result in fully deterministic output. It is best effort.

## See Also

Sampling modes greedy and random(top:seed:)

## See Also

Sampling options
static var greedy: GenerationOptions.SamplingMode
A sampling mode that always chooses the most likely token.
static func random(top: Int, seed: UInt64?) -> GenerationOptions.SamplingMode
A sampling mode that considers a fixed number of high-probability tokens.



## Type Method

random(top:seed:)
A sampling mode that considers a fixed number of high-probability tokens.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func random(

```swift
    top k: Int,
    seed: UInt64? = nil
```
) -> GenerationOptions.SamplingMode

## Parameters

k
The number of tokens to consider.
seed
An optional random seed used to make output more deterministic.

## Discussion

Also known as top-k.
During the token-selection process, the vocabulary is sorted by probability a token is selected from among the top K candidates. Smaller values of K will ensure only the most probable tokens are candidates for selection, resulting in more deterministic and confident answers. Larger values of K will allow less probably tokens to be selected, raising non-determinism and creativity.
Note
Setting a random seed is not guaranteed to result in fully deterministic output. It is best effort.

## See Also

Sampling modes greedy and random(probabilityThreshold:seed:)

## See Also

Sampling options
static var greedy: GenerationOptions.SamplingMode
A sampling mode that always chooses the most likely token.
static func random(probabilityThreshold: Double, seed: UInt64?) -> GenerationOptions.SamplingMode
A mode that considers a variable number of high-probability tokens based on the specified threshold.



## Instance Property

temperature
Temperature influences the confidence of the models response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var temperature: Double?
```

## Discussion

The value of this property must be a number between 0 and 1 inclusive.
Temperature is an adjustment applied to the probability distribution prior to sampling. A value of 1 results in no adjustment. Values less than 1 will make the probability distribution sharper, with already likely tokens becoming even more likely.
The net effect is that low temperatures manifest as more stable and predictable responses, while high temperatures give the model more creative license.
Note
Leaving temperature nil lets the system choose a reasonable default on your behalf.



# Article

Generating Swift data structures with guided generation
Create robust apps by describing output you want programmatically.

## Overview

When you perform a request, the model returns a raw string in its natural language format. Raw strings require you to manually parse the details you want. Instead of working with raw strings, the framework provides guided generation, which gives strong guarantees that the response is in a format you expect.
To use guided generation, describe the output you want as a new Swift type. When you make a request to the model, include your custom type and the framework performs the work necessary to fill in and return an object with the parameters filled in for you. The framework uses constrained sampling when generating output, which defines the rules on what the model can generate. Constrained sampling prevents the model from producing malformed output and provides you with results as a type you define.
For more information about creating a session and prompting the model, see Generating content and performing tasks with Foundation Models.
Conform your data type to Generable
To conform your type to Generable, describe the type and the parameters to guide the response of the model. The framework supports generating content with basic Swift types like Bool, Int, Float, Double, Decimal, and Array. For example, if you only want the model to return a numeric result, call respond(to:generating:includeSchemaInPrompt:options:) using the type Float:

```swift
let prompt = "How many tablespoons are in a cup?"
let session = LanguageModelSession(model: .default)


```
// Generate a response with the type `Float`, instead of `String`.

```swift
let response = try await session.respond(to: prompt, generating: Float.self)
```
A schema provides the ability to control the values of a property, and you can specify guides to control values you associate with it. The framework provides two macros that help you with schema creation. Use Generable(description:) on structures, actors, and enumerations; and only use Guide(description:) with stored properties.
When you add descriptions to Generable properties, you help the model understand the semantics of the properties. Keep the descriptions as short as possible — long descriptions take up additional context size and can introduce latency. The following example creates a type that describes a cat and includes a name, an age that’s constrained to a range of values, and a short profile:

```swift
@Generable(description: "Basic profile information about a cat")
struct CatProfile {
    // A guide isn't necessary for basic fields.
    var name: String


    @Guide(description: "The age of the cat", .range(0...20))
    var age: Int


    @Guide(description: "A one sentence profile about the cat's personality")
    var profile: String
}
```
Note
The model generates Generable properties in the order they’re declared.
You can nest custom Generable types inside other Generable types, and mark enumerations with associated values as Generable. The Generable macro ensures that all associated and nested values are themselves generable. This allows for advanced use cases like creating complex data types or dynamically generating views at runtime.
Make a request with your custom data type
After creating your type, use it along with a LanguageModelSession to prompt the model. When you use a Generable type it prevents the model from producing malformed output and prevents the need for any manual string parsing.
// Generate a response using a custom type.

```swift
let response = try await session.respond(
    to: "Generate a cute rescue cat",
    generating: CatProfile.self
```
)
Define a dynamic schema at runtime
If you don’t know what you want the model to produce at compile time use DynamicGenerationSchema to define what you need. For example, when you’re working on a restaurant app and want to restrict the model to pick from menu options that a restaurant provides. Because each restaurant provides a different menu, the schema won’t be known in its entirety until runtime.
// Create the dynamic schema at runtime.

```swift
let menuSchema = DynamicGenerationSchema(
    name: "Menu",
    properties: [
        DynamicGenerationSchema.Property(
            name: "dailySoup",
            schema: DynamicGenerationSchema(
                name: "dailySoup",
                anyOf: ["Tomato", "Chicken Noodle", "Clam Chowder"]
            )
        )


        // Add additional properties.
    ]
```
)
After creating a dynamic schema, use it to create a GenerationSchema that you provide with your request. When you try to create a generation schema, it can throw an error if there are conflicting property names, undefined references, or duplicate types.
// Create the schema.

```swift
let schema = try GenerationSchema(root: menuSchema, dependencies: [])


```
// Pass the schema to the model to guide the output.

```swift
let response = try await session.respond(
    to: "The prompt you want to make.",
    schema: schema
```
)
The response you get is an instance of GeneratedContent. You can decode the outputs from schemas you define at runtime by calling value(_:forProperty:) for the property you want.

## See Also

Guided generation

```swift
protocol Generable
```
A type that the model uses when responding to prompts.



# Protocol

Generable
A type that the model uses when responding to prompts.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
protocol Generable : ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent
```

## Mentioned in


Analyzing the runtime performance of your Foundation Models app

Prompting an on-device foundation model

Categorizing and organizing data with content tags

Generating Swift data structures with guided generation

## Overview

Annotate your Swift structure or enumeration with the Generable macro to allow the model to respond to prompts by generating an instance of your type. Use the Guide macro to provide natural language descriptions of your properties, and programmatically control the values that the model can generate.

```swift
@Generable
struct SearchSuggestions {
    @Guide(description: "A list of suggested search terms.", .count(4))
    var searchTerms: [SearchTerm]
    @Generable
    struct SearchTerm {
        // Use a generation identifier for data structures the framework generates.
        var id: GenerationID
        @Guide(description: "A two- or three- word search term, like 'Beautiful sunsets'.")
        var searchTerm: String
    }
}
```
For every Generable type in a request, the framework converts its type and format information to a JSON schema and provides it to the model. This contributes to the available context window size. If the LanguageModelSession exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:). To reduce the size of your generable type:
- Reduce the complexity of your Generable type by evaluating whether properties are necessary to complete the task.
- Give your properties short and clear names.
- Use Guide(description:) on properties only when it improves response quality.
- Add a Guide(description:_:) with maximumCount(_:) to reduce token usage.
If the Generable type includes properties with clear names the model may have all it needs to generate your type, eliminating the need of Guide(description:). For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Defining a generable type
macro Generable(description: String?)
Conforms a type to Generable protocol.
Creating a guide
macro Guide(description: String)
Allows for influencing the allowed values of properties of a Generable type.
macro Guide(description:_:)
Allows for influencing the allowed values of properties of a Generable type.

```swift
struct GenerationGuide
```
Guides that control how values are generated.
Getting the schema
static var generationSchema: GenerationSchema
An instance of the generation schema.
Required

```swift
struct GenerationSchema
```
A type that describes the properties of an object and any guides on their values.
Generating a unique identifier

```swift
struct GenerationID
```
A unique identifier that is stable for the duration of a response, but not across responses.
Converting to partially generated

```swift
func asPartiallyGenerated() -> Self.PartiallyGenerated
```
The partially generated type of this struct.
associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self
A representation of partially generated content
Required Default implementation provided.
Generate dynamic shemas

```swift
struct DynamicGenerationSchema
```
The dynamic counterpart to the generation schema type that you use to construct schemas at runtime.

## Relationships

Inherits From
- ConvertibleFromGeneratedContent
- ConvertibleToGeneratedContent
- InstructionsRepresentable
- PromptRepresentable
- SendableMetatype

## Conforming Types

- GeneratedContent

## See Also

Guided generation

Generating Swift data structures with guided generation
Create robust apps by describing output you want programmatically.


Macro
Generable(description:)
Conforms a type to Generable protocol.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@attached(extension, conformances: Generable, names: named(init(_:)), named(generatedContent)) @attached(member, names: arbitrary)
macro Generable(description: String? = nil)

## Mentioned in


Generating Swift data structures with guided generation

## Overview

You can apply this macro to structures and enumerations.

```swift
@Generable
struct NovelIdea {
  @Guide(description: "A short title")
  let title: String


  @Guide(description: "A short subtitle for the novel")
  let subtitle: String


  @Guide(description: "The genre of the novel")
  let genre: Genre
}


@Generable
enum Genre {
  case fiction
  case nonFiction
}
```

## See Also


```swift
@Guide macro Guide(description:)


```
Macro
Guide(description:)
Allows for influencing the allowed values of properties of a Generable type.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@attached(peer)
macro Guide(description: String)

## Mentioned in


Generating Swift data structures with guided generation

## Overview


## See Also


```swift
@Generable macro Generable(description:)
```

## See Also

Creating a guide
macro Guide(description:_:)
Allows for influencing the allowed values of properties of a Generable type.

```swift
struct GenerationGuide
```
Guides that control how values are generated.


Macro
Guide(description:_:)
Allows for influencing the allowed values of properties of a Generable type.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@attached(peer)
macro Guide<RegexOutput>(

```swift
    description: String? = nil,
    _ guides: Regex<RegexOutput>
```
)
Show all declarations


## Overview


## See Also


```swift
@Generable macro Generable(description:)
```

## See Also

Creating a guide
macro Guide(description: String)
Allows for influencing the allowed values of properties of a Generable type.

```swift
struct GenerationGuide
```
Guides that control how values are generated.



# Structure

GenerationGuide
Guides that control how values are generated.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct GenerationGuide<Value>
```

## Mentioned in


Categorizing and organizing data with content tags

## Topics

Getting the pattern
static func pattern<Output>(Regex<Output>) -> GenerationGuide<String>
Enforces that the string follows the pattern.
Getting the element
static func element<Element>(GenerationGuide<Element>) -> GenerationGuide<[Element]>
Enforces a guide on the elements within the array.
Getting the count
static count(_:)
Enforces that the array has exactly a certain number elements.
Getting the constant
static func constant(String) -> GenerationGuide<String>
Enforces that the string be precisely the given value.
static func anyOf([String]) -> GenerationGuide<String>
Enforces that the string be one of the provided values.
Getting a range
static range(_:)
Enforces values fall within a range.
Getting the minimum value
static minimum(_:)
Enforces a minimum value.
static func minimumCount<Element>(Int) -> GenerationGuide<[Element]>
Enforces a minimum number of elements in the array.
Getting the maximum value
static maximum(_:)
Enforces a maximum value.
static func maximumCount<Element>(Int) -> GenerationGuide<[Element]>
Enforces a maximum number of elements in the array.

## See Also

Creating a guide
macro Guide(description: String)
Allows for influencing the allowed values of properties of a Generable type.
macro Guide(description:_:)
Allows for influencing the allowed values of properties of a Generable type.



## Type Method

pattern(_:)
Enforces that the string follows the pattern.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func pattern<Output>(_ regex: Regex<Output>) -> GenerationGuide<String>
Available when Value is String.



## Type Method

element(_:)
Enforces a guide on the elements within the array.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func element<Element>(_ guide: GenerationGuide<Element>) -> GenerationGuide<[Element]> where Value == [Element]

## Discussion

An element generation guide may be used when you want to apply guides to the values a model produces within an array. For example, you may want to generate an array of integers, where all the integers are in the range 0-9.

```swift
@Generable
struct struct FortuneCookie {
    @Guide(description: "A fortune from a fortune cookie"
    var name: String


    @Guide(description: "A list lucky numbers", .element(.range(0...9)), .count(4))
    var luckyNumbers: [Int]
}


```

## Type Method

count(_:)
Enforces that the array has exactly a certain number elements.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func count<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]
Show all declarations


## Discussion

A count generation guide may be used when you want to ensure the model produces exactly a certain number array elements, such as the number of items in a game’s shop.

```swift
@Generable
struct struct Shop {
    @Guide(description: "A creative name for a shop in a fantasy RPG"
    var name: String


    @Guide(description: "A list of items for sale", .count(3))
    var inventory: [ShopItem]
}


```

## Type Method

constant(_:)
Enforces that the string be precisely the given value.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func constant(_ value: String) -> GenerationGuide<String>
Available when Value is String.

## See Also

Getting the constant
static func anyOf([String]) -> GenerationGuide<String>
Enforces that the string be one of the provided values.



## Type Method

anyOf(_:)
Enforces that the string be one of the provided values.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func anyOf(_ values: [String]) -> GenerationGuide<String>
Available when Value is String.

## See Also

Getting the constant
static func constant(String) -> GenerationGuide<String>
Enforces that the string be precisely the given value.




## Type Method

range(_:)
Enforces values fall within a range.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func range(_ range: ClosedRange<Decimal>) -> GenerationGuide<Decimal>
Available when Value is Decimal.
Show all declarations


## Discussion

Use a range generation guide — whose bounds are inclusive — to ensure the model produces a value that falls within a range. For example, you can specify that the level of characters in your game are between 1 and 100:

```swift
@Generable
struct GameCharacter {
    @Guide(description: "A creative name appropriate for a fantasy RPG character")
    var name: String


    @Guide(description: "A level for the character", .range(1...100))
    var level: Int
}

```

## Type Method

minimum(_:)
Enforces a minimum value.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func minimum(_ value: Decimal) -> GenerationGuide<Decimal>
Available when Value is Decimal.
Show all declarations


## Discussion

Use a minimum generation guide — whose bounds are inclusive — to ensure the model produces a value greater than or equal to some minimum value. For example, you can specify that all characters in your game start at level 1:

```swift
@Generable
struct GameCharacter {
    @Guide(description: "A creative name appropriate for a fantasy RPG character")
    var name: String


    @Guide(description: "A level for the character", .minimum(1))
    var level: Int
}
```

## See Also

Getting the minimum value
static func minimumCount<Element>(Int) -> GenerationGuide<[Element]>
Enforces a minimum number of elements in the array.



## Type Method

minimumCount(_:)
Enforces a minimum number of elements in the array.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func minimumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]

## Discussion

The bounds are inclusive.
A minimumCount generation guide may be used when you want to ensure the model produces a number of array elements greater than or equal to to some minimum value, such as the number of items in a game’s shop.

```swift
@Generable
struct struct Shop {
    @Guide(description: "A creative name for a shop in a fantasy RPG"
    var name: String


    @Guide(description: "A list of items for sale", .minimumCount(3))
    var inventory: [ShopItem]
}
```

## See Also

Getting the minimum value
static minimum(_:)
Enforces a minimum value.



## Type Method

maximum(_:)
Enforces a maximum value.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func maximum(_ value: Decimal) -> GenerationGuide<Decimal>
Available when Value is Decimal.
Show all declarations


## Discussion

Use a maximum generation guide — whose bounds are inclusive — to ensure the model produces a value less than or equal to some maximum value. For example, you can specify that the highest level a character in your game can achieve is 100:

```swift
@Generable
struct GameCharacter {
    @Guide(description: "A creative name appropriate for a fantasy RPG character")
    var name: String


    @Guide(description: "A level for the character", .maximum(100))
    var level: Int
}
```

## See Also

Getting the maximum value
static func maximumCount<Element>(Int) -> GenerationGuide<[Element]>
Enforces a maximum number of elements in the array.



## Type Method

maximumCount(_:)
Enforces a maximum number of elements in the array.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
static func maximumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element]

## Mentioned in


Categorizing and organizing data with content tags

## Discussion

The bounds are inclusive.
A maximumCount generation guide may be used when you want to ensure the model produces a number of array elements less than or equal to to some maximum value, such as the number of items in a game’s shop.

```swift
@Generable
struct struct Shop {
    @Guide(description: "A creative name for a shop in a fantasy RPG"
    var name: String


    @Guide(description: "A list of items for sale", .maximumCount(10))
    var inventory: [ShopItem]
}
```

## See Also

Getting the maximum value
static maximum(_:)
Enforces a maximum value.



## Type Property

generationSchema
An instance of the generation schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
static var generationSchema: GenerationSchema { get }
```
Required

## See Also

Getting the schema

```swift
struct GenerationSchema
```
A type that describes the properties of an object and any guides on their values.




# Structure

GenerationSchema
A type that describes the properties of an object and any guides on their values.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct GenerationSchema
```

## Mentioned in


Generating Swift data structures with guided generation

## Overview

Generation schemas guide the output of a SystemLanguageModel to deterministically ensure the output is in the desired format.

## Topics

Creating a generation schema

```swift
init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws
```
Creates a schema by providing an array of dynamic schemas.

```swift
init(type:description:anyOf:)
```
Creates a schema for a string enumeration.

```swift
init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property])
```
Creates a schema by providing an array of properties.

```swift
struct Property
```
A property that belongs to a generation schema.
Getting the debug description

```swift
var debugDescription: String
```
A string representation of the debug description.
Getting the generation schema error types

```swift
enum SchemaError
```
A error that occurs when there is a problem creating a generation schema.

## Relationships


## Conforms To

- CustomDebugStringConvertible
- Decodable
- Encodable
- Sendable
- SendableMetatype

## See Also

Getting the schema
static var generationSchema: GenerationSchema
An instance of the generation schema.
Required



## Initializer


```swift
init(root:dependencies:)
```
Creates a schema by providing an array of dynamic schemas.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    root: DynamicGenerationSchema,
    dependencies: [DynamicGenerationSchema]
```
) throws

## Parameters

root
The root schema.
dependencies
An array of dynamic schemas.

## Discussion


## Throws

Throws there are schemas with naming conflicts or references to undefined types.

## See Also

Creating a generation schema

```swift
init(type:description:anyOf:)
```
Creates a schema for a string enumeration.

```swift
init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property])
```
Creates a schema by providing an array of properties.

```swift
struct Property
```
A property that belongs to a generation schema.



## Initializer


```swift
init(type:description:anyOf:)
```
Creates a schema for a string enumeration.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    type: any Generable.Type,
    description: String? = nil,
    anyOf choices: [String]
```
)
Show all declarations


## Parameters

type
The type this schema represents.
description
A natural language description of this schema.

## See Also

Creating a generation schema

```swift
init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws
```
Creates a schema by providing an array of dynamic schemas.

```swift
init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property])
```
Creates a schema by providing an array of properties.

```swift
struct Property
```
A property that belongs to a generation schema.



## Initializer


```swift
init(type:description:properties:)
```
Creates a schema by providing an array of properties.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    type: any Generable.Type,
    description: String? = nil,
    properties: [GenerationSchema.Property]
```
)

## Parameters

type
The type this schema represents.
description
A natural language description of this schema.
properties
An array of properties.

## See Also

Creating a generation schema

```swift
init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws
```
Creates a schema by providing an array of dynamic schemas.

```swift
init(type:description:anyOf:)
```
Creates a schema for a string enumeration.

```swift
struct Property
```
A property that belongs to a generation schema.



# Structure

GenerationSchema.Property
A property that belongs to a generation schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Property
```

## Overview

Fields are named members of object types. Fields are strongly typed and have optional descriptions and guides.

## Topics

Creating a property

```swift
init(name:description:type:guides:)
```
Create a property that contains a string type.

## Relationships


## Conforms To

- Sendable
- SendableMetatype

## See Also

Creating a generation schema

```swift
init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws
```
Creates a schema by providing an array of dynamic schemas.

```swift
init(type:description:anyOf:)
```
Creates a schema for a string enumeration.

```swift
init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property])
```
Creates a schema by providing an array of properties.



## Initializer


```swift
init(name:description:type:guides:)
```
Create a property that contains a string type.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init<RegexOutput>(
    name: String,
    description: String? = nil,
    type: String.Type,
    guides: [Regex<RegexOutput>] = []
```
)
Show all declarations


## Parameters

name
The property’s name.
description
A natural language description of what content should be generated for this property.
type
The type this property represents.
guides
An array of regexes to be applied to this string. If there’re multiple regexes in the array, only the last one will be applied.



## Instance Property

debugDescription
A string representation of the debug description.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var debugDescription: String { get }
```

## Discussion

This string is not localized and is not appropriate for display to end users.



# Enumeration

GenerationSchema.SchemaError
A error that occurs when there is a problem creating a generation schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum SchemaError
```

## Topics

Getting schema errors

```swift
case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.

```swift
case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.

```swift
case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct an anyOf schema with an empty array of type choices.

```swift
case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.

```swift
struct Context
```
The context in which the error occurred.
Getting the error description

```swift
var errorDescription: String?
```
A string representation of the error description.
Getting the recovery suggestion

```swift
var recoverySuggestion: String?
```
A suggestion that indicates how to handle the error.

## Relationships


## Conforms To

- Error
- LocalizedError
- Sendable
- SendableMetatype


Case
GenerationSchema.SchemaError.duplicateProperty(schema:property:context:)
An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case duplicateProperty(
    schema: String,
    property: String,
    context: GenerationSchema.SchemaError.Context
```
)

## See Also

Getting schema errors

```swift
case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.

```swift
case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct an anyOf schema with an empty array of type choices.

```swift
case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.

```swift
struct Context
```
The context in which the error occurred.


Case
GenerationSchema.SchemaError.duplicateType(schema:type:context:)
An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case duplicateType(
    schema: String?,
    type: String,
    context: GenerationSchema.SchemaError.Context
```
)

## See Also

Getting schema errors

```swift
case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.

```swift
case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct an anyOf schema with an empty array of type choices.

```swift
case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.

```swift
struct Context
```
The context in which the error occurred.


Case
GenerationSchema.SchemaError.emptyTypeChoices(schema:context:)
An error that represents an attempt to construct an anyOf schema with an empty array of type choices.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case emptyTypeChoices(
    schema: String,
    context: GenerationSchema.SchemaError.Context
```
)

## See Also

Getting schema errors

```swift
case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.

```swift
case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.

```swift
case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.

```swift
struct Context
```
The context in which the error occurred.


Case
GenerationSchema.SchemaError.undefinedReferences(schema:references:context:)
An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case undefinedReferences(
    schema: String?,
    references: [String],
    context: GenerationSchema.SchemaError.Context
```
)

## See Also

Getting schema errors

```swift
case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.

```swift
case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.

```swift
case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct an anyOf schema with an empty array of type choices.

```swift
struct Context
```
The context in which the error occurred.



# Structure

GenerationSchema.SchemaError.Context
The context in which the error occurred.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Context
```

## Topics

Creating a schema error context

```swift
init(debugDescription: String)
```
Getting the debug description

```swift
let debugDescription: String
```
A string representation of the debug description.

## Relationships


## Conforms To

- Sendable
- SendableMetatype

## See Also

Getting schema errors

```swift
case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.

```swift
case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.

```swift
case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct an anyOf schema with an empty array of type choices.

```swift
case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)
```
An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.



## Initializer


```swift
init(debugDescription:)
```
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(debugDescription: String)


```

## Instance Property

debugDescription
A string representation of the debug description.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
let debugDescription: String
```

## Discussion

This string is not localized and is not appropriate for display to end users.




## Instance Property

errorDescription
A string representation of the error description.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var errorDescription: String? { get }


```

## Instance Property

recoverySuggestion
A suggestion that indicates how to handle the error.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var recoverySuggestion: String? { get }


```

# Structure

GenerationID
A unique identifier that is stable for the duration of a response, but not across responses.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct GenerationID
```

## Overview

The framework guarantees a GenerationID to be both present and stable when you receive it from a LanguageModelSession. When you create an instance of GenerationID there is no guarantee an identifier is present or stable.

```swift
@Generable
struct Person: Equatable {
    var name: String
}


struct PeopleView: View {
    @State private var session = LanguageModelSession()
    @State private var people = [Person.PartiallyGenerated]()
    
    var body: some View {
        // A person's name changes as the response is generated,
        // and two people can have the same name, so it's not suitable
        // for use as an id.
        //
        // `GenerationID` receives special treatment and is guaranteed
        // to be both present and stable.
        List {
            // The framework generates each instance with a `GenerationID`.
            ForEach(people, id: \.id) { person in
                Text("Name: \(person.name ?? "")")
            }
        }
        .task {
            do {
                for try await people in session.streamResponse(
                    to: "Who were the first 3 presidents of the US?",
                    generating: [Person].self
                ) {
                    withAnimation {
                        self.people = people.content
                    }
                }
            } catch {
                // Handle the thrown error.
            }
        }
    }
}
```

## Topics

Creating an identifier

```swift
init()
```
Create a new, unique GenerationID.

## Relationships


## Conforms To

- Equatable
- Hashable
- Sendable
- SendableMetatype



## Initializer


```swift
init()
```
Create a new, unique GenerationID.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init()


```

## Instance Method

asPartiallyGenerated()
The partially generated type of this struct.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
func asPartiallyGenerated() -> Self.PartiallyGenerated
```

## See Also

Converting to partially generated
associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self
A representation of partially generated content
Required Default implementation provided.


Associated Type
PartiallyGenerated
A representation of partially generated content
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self
Required Default implementation provided.

## Default Implementations

Generable Implementations
typealias PartiallyGenerated
A representation of partially generated content

## See Also

Converting to partially generated

```swift
func asPartiallyGenerated() -> Self.PartiallyGenerated
```
The partially generated type of this struct.



# Structure

DynamicGenerationSchema
The dynamic counterpart to the generation schema type that you use to construct schemas at runtime.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct DynamicGenerationSchema
```

## Mentioned in


Generating Swift data structures with guided generation

## Overview

An individual schema may reference other schemas by name, and references are resolved when converting a set of dynamic schemas into a GenerationSchema.

## Topics

Creating a dynamic schema

```swift
init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)
```
Creates an array schema.

```swift
init(name:description:anyOf:)
```
Creates an any-of schema.

```swift
init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])
```
Creates an object schema.

```swift
init(referenceTo: String)
```
Creates an refrence schema.

```swift
init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])
```
Creates a schema from a generable type and guides.

```swift
struct Property
```
A property that belongs to a dynamic generation schema.

## Relationships


## Conforms To

- Sendable
- SendableMetatype



## Initializer


```swift
init(arrayOf:minimumElements:maximumElements:)
```
Creates an array schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    arrayOf itemSchema: DynamicGenerationSchema,
    minimumElements: Int? = nil,
    maximumElements: Int? = nil
```
)

## See Also

Creating a dynamic schema

```swift
init(name:description:anyOf:)
```
Creates an any-of schema.

```swift
init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])
```
Creates an object schema.

```swift
init(referenceTo: String)
```
Creates an refrence schema.

```swift
init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])
```
Creates a schema from a generable type and guides.

```swift
struct Property
```
A property that belongs to a dynamic generation schema.



## Initializer


```swift
init(name:description:anyOf:)
```
Creates an any-of schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    name: String,
    description: String? = nil,
    anyOf choices: [DynamicGenerationSchema]
```
)
Show all declarations


## Parameters

name
A name this schema can be referenecd by.
description
A natural language description of this DynamicGenerationSchema.
choices
An array of schemas this one will be a union of.

## See Also

Creating a dynamic schema

```swift
init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)
```
Creates an array schema.

```swift
init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])
```
Creates an object schema.

```swift
init(referenceTo: String)
```
Creates an refrence schema.

```swift
init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])
```
Creates a schema from a generable type and guides.

```swift
struct Property
```
A property that belongs to a dynamic generation schema.



## Initializer


```swift
init(name:description:properties:)
```
Creates an object schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    name: String,
    description: String? = nil,
    properties: [DynamicGenerationSchema.Property]
```
)

## Parameters

name
A name this dynamic schema can be referenced by.
description
A natural language description of this schema.
properties
The properties to associated with this schema.

## See Also

Creating a dynamic schema

```swift
init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)
```
Creates an array schema.

```swift
init(name:description:anyOf:)
```
Creates an any-of schema.

```swift
init(referenceTo: String)
```
Creates an refrence schema.

```swift
init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])
```
Creates a schema from a generable type and guides.

```swift
struct Property
```
A property that belongs to a dynamic generation schema.



## Initializer


```swift
init(referenceTo:)
```
Creates an refrence schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(referenceTo name: String)
```

## Parameters

name
The name of the DynamicGenerationSchema this is a reference to.

## See Also

Creating a dynamic schema

```swift
init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)
```
Creates an array schema.

```swift
init(name:description:anyOf:)
```
Creates an any-of schema.

```swift
init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])
```
Creates an object schema.

```swift
init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])
```
Creates a schema from a generable type and guides.

```swift
struct Property
```
A property that belongs to a dynamic generation schema.



## Initializer


```swift
init(type:guides:)
```
Creates a schema from a generable type and guides.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init<Value>(
    type: Value.Type,
    guides: [GenerationGuide<Value>] = []
```
) where Value : Generable

## Parameters

type
A Generable type
guides
Generation guides to apply to this DynamicGenerationSchema.

## See Also

Creating a dynamic schema

```swift
init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)
```
Creates an array schema.

```swift
init(name:description:anyOf:)
```
Creates an any-of schema.

```swift
init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])
```
Creates an object schema.

```swift
init(referenceTo: String)
```
Creates an refrence schema.

```swift
struct Property
```
A property that belongs to a dynamic generation schema.



# Structure

DynamicGenerationSchema.Property
A property that belongs to a dynamic generation schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Property
```

## Overview

Fields are named members of object types. Fields are strongly typed and have optional descriptions.

## Topics

Creating a property

```swift
init(name: String, description: String?, schema: DynamicGenerationSchema, isOptional: Bool)
```
Creates a property referencing a dynamic schema.

## See Also

Creating a dynamic schema

```swift
init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)
```
Creates an array schema.

```swift
init(name:description:anyOf:)
```
Creates an any-of schema.

```swift
init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])
```
Creates an object schema.

```swift
init(referenceTo: String)
```
Creates an refrence schema.

```swift
init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])
```
Creates a schema from a generable type and guides.


## Initializer


```swift
init(name:description:schema:isOptional:)
```
Creates a property referencing a dynamic schema.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    name: String,
    description: String? = nil,
    schema: DynamicGenerationSchema,
    isOptional: Bool = false
```
)

## Parameters

name
A name for this property.
description
An optional natural language description of this property’s contents.
schema
A schema representing the type this property contains.
isOptional
Determines if this property is required or not.



# Article

Expanding generation with tool calling
Build tools that enable the model to perform tasks that are specific to your use case.

## Overview

Tools provide a way to extend the functionality of the model for your own use cases. Tool-calling allows the model to interact with external code you create to fetch up-to-date information, ground responses in sources of truth that you provide, and perform side effects, like turning on dark mode.
You can create tools that enable the model to:
- Query entries from your app’s database and reference them in its answer.
- Perform actions within your app, like adjusting the difficulty in a game or making a web request to get additional information.
- Integrate with other frameworks, like Contacts or HealthKit, that use existing privacy and security mechanisms.
Create a custom tool for your task
When you prompt the model with a question or make a request, the model decides whether it can provide an answer or if it needs the help of a tool. When the model determines that a tool can help, it calls the tool with additional arguments that the tool can use. After the tool completes the task, it returns control back to the model with information about what the tool did. The model can then use the output of the tool when it provides the final response.
Before creating a tool, it’s helpful to understand the pattern the framework follows when using the tool you provide. The framework processes a request in six phases:
	1	You present a list of available tools and their parameters to the model.
	2	You submit your prompt to the model.
	3	The model generates arguments to the tool(s) it wants to invoke.
	4	Your tool runs code on behalf of the model, using the model’s generated arguments.
	5	Your tool passes its output back to the model.
	6	The model produces a final response to the prompt, based on the tool output.
A tool conforms to Tool and contains the arguments that the tool accepts, and a method that the model calls when it wants to use the tool. You can call call(arguments:) concurrently with itself or with other tools. The following example shows a tool that accepts a search term and a number of recipes to retrieve:

```swift
struct BreadDatabaseTool: Tool {
    let name = "searchBreadDatabase"
    let description = "Searches a local database for bread recipes."


    @Generable
    struct Arguments {
        @Guide(description: "The type of bread to search for")
        var searchTerm: String
        @Guide(description: "The number of recipes to get", .range(1...6))
        var limit: Int
    }


    struct Recipe {
        var name: String
        var description: String
        var link: URL
    }
    
    func call(arguments: Arguments) async throws -> [String] {
        var recipes: [Recipe] = []
        
        // Put your code here to retrieve a list of recipes from your database.
        
        let formattedRecipes = recipes.map {
            "Recipe for '\($0.name)': \($0.description) Link: \($0.link)"
        }
        return formattedRecipes
    }
}
```
When you provide descriptions to generable properties, you help the model understand the semantics of the arguments. Keep descriptions as short as possible because long descriptions take up context size and can introduce latency. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.
Tools use guided generation for the Arguments property. For more information about guided generation, see Generating Swift data structures with guided generation.
Provide a session with the tool you create
When you create a session, you can provide a list of tools that are relevant to the task you want to complete. The tools you provide are available for all future interactions with the session. The following example initializes a session with a tool that the model can call when it determines that it would help satisfy the prompt:

```swift
let session = LanguageModelSession(
    tools: [BreadDatabaseTool()]
```
)



```swift
let response = try await session.respond(
    to: "Find three sourdough bread recipes"
```
)
Tool output can be a string, or a GeneratedContent object. The model can call a tool multiple times in parallel to satisfy the request, like when retrieving weather details for several cities:

```swift
struct WeatherTool: Tool {
  let name = "getWeather"
  let description = "Retrieve the latest weather information for a city"


  @Generable
  struct Arguments {
      @Guide(description: "The city to get weather information for")
      var city: String
  }


  struct Forecast: Encodable {
      var city: String
      var temperature: Int
  }


  func call(arguments: Arguments) async throws -> String {
      // Get a random temperature value. Use `WeatherKit` to get 
      // a temperature for the city.
      let temperature = Int.random(in: 30...100)
      let formattedResult = """
          The forecast for '\(arguments.city)' is '\(temperature)' \
          degrees Fahrenheit. 
          """
      return formattedResult
  }
}


```
// Create a session with default instructions that guide the requests.

```swift
let session = LanguageModelSession(
    tools: [WeatherTool()],
    instructions: "Help the person with getting weather information"
```
)


// Make a request that compares the temperature between several locations.

```swift
let response = try await session.respond(
    to: "Is it hotter in Boston, Wichita, or Pittsburgh?"
```
)
Handle errors thrown by a tool
When an error happens during tool calling, the session throws a LanguageModelSession.ToolCallError with the underlying error and includes the tool that throws the error. This helps you understand the error that happened during the tool call, and any custom error types that your tool produces. You can throw errors from your tools to escape calls when you detect something is wrong, like when the person using your app doesn’t allow access to the required data or a network call is taking longer than expected. Alternatively, your tool can return a string that briefly tells the model what didn’t work, like “Cannot access the database.”

```swift
do {
    let answer = try await session.respond("Find a recipe for tomato soup.")
} catch let error as LanguageModelSession.ToolCallError {
        
    // Access the name of the tool, like BreadDatabaseTool.
    print(error.tool.name) 
        
    // Access an underlying error that your tool throws and check if the tool 
    // encounters a specific condition.
    if case .databaseIsEmpty = error.underlyingError as? SearchBreadDatabaseToolError {
        // Display an error in the UI.
    }


} catch {
    print("Some other error: \(error)")
}
```
Inspect the call graph
A session contains an observable transcript property that allows you to track when, and how many times, the model calls your tools. A transcript also provides the ability to construct a representation of the call graph for debugging purposes and pairs well with SwiftUI to visualize session history.

```swift
struct MyHistoryView: View {


    @State
    var session = LanguageModelSession(
        tools: [BreadDatabaseTool()]
    )
    
    var body: some View {
        List(session.transcript) { entry in
            switch entry {       
            case .instructions(let instructions):
                // Display the instructions the model uses.
            case .prompt(let prompt):
                // Display the prompt made to the model.
            case .toolCall(let call):
                // Display the call details for a tool, like the tool name and arguments.        
            case .toolOutput(let output):
                // Display the output that a tool provides back to the model.        
            case .response(let response):
                // Display the response from the model.
            }
        }.task {
            do {
                try await session.respond(to: "Find a milk bread recipe.")
            } catch let error {
                // Handle the error.
            }
        }
    }
    
}
```

## See Also

Tool calling

Generate dynamic game content with guided generation and tools
Make gameplay more lively with AI generated dialog and encounters personalized to the player.

```swift
protocol Tool
```
A tool that a model can call to gather information at runtime or perform side effects.



# Sample Code

Generate dynamic game content with guided generation and tools
Make gameplay more lively with AI generated dialog and encounters personalized to the player.
Download
> iOS 26.0+
> iPadOS 26.0+
> macOS 26.0+
> Xcode 26.0+

## Overview

This sample code project demonstrates the Foundation Models framework and its ability to generate dynamic content for a game. Instead of using the same dialog script for customer encounters, the app dynamically generates dialog so that each time a player talks to a character, they can have a different conversation.
￼
The game combines several framework capabilities — like guided generation and tool calling — to create dynamic, personalized gameplay experiences. You interact with both scripted characters, like the head barista, and procedurally generated customers, each with unique personalities, appearances, and coffee orders. As you serve customers, you can engage in conversations, take custom coffee orders, and receive feedback on your brewing skills — all powered by an on-device foundation model.
Note
This sample code project is associated with WWDC25 sessions 301: Deep Dive into the Foundation Models Framework.
Generate character dialog
The sample app generates dialog for characters by using Character to describe the character, like the barista:

```swift
struct Barista: Character {
    let id = UUID()
    let displayName = "Barista"
    let firstLine = "Hey there. Can you get the dream orders?"


    let persona = """
        Chike is the head barista at Dream Coffee, and loves serving up the perfect cup of coffee 
        to all the dreamers and creatures in the dream realm. Today is a particularly busy day, so 
        Chike is happy to have the help of a new trainee barista named Player.
        """


    let errorResponse = "Maybe let's stop chatting? We've got coffee to serve."
}
```
A persona is a detailed description of the character that the model should pretend to be. The app uses a fixed error response when it encounters a generation error or content that the system blocks for safety.
The DialogEngine class manages conoversations for all characters in the game using LanguageModelSession. Each character maintains their own conversation session, allowing for persistent, contextual dialog that remembers previous interactions. When a conversation begins with a character, the dialog engine creates a new session with specific instructions that define the character’s personality and role:

```swift
let instructions = """
    A multiturn conversation between a game character and the player of this game. \
    You are \(character.displayName). Refer to \(character.displayName) in the first-person \
    (like "I" or "me"). You must respond in the voice of \(character.persona).\

    Keep your responses short and positive. Remember: Because this is the dream realm, \
    everything is free at this coffee shop and the baristas are paid in creative inpiration.

    You just said: "\(startWith)"
    """
```
When the player provides input text to talk to the character, the sample app uses the input as a prompt to the session. When generating a response, the dialog engine includes safety mechanisms to keep conversations on topic. It maintains block lists for words and phrases that characters shouldn’t discuss, ensuring nonplayer characters (NPCs) focus on coffee-related topics. If the app generates content containing blocked terms, it automatically resets the conversation and provides the default error response for the character.

```swift
let response = try await session.respond(
    to: userInput
```
)

```swift
let dialog = response.content


```
// Verify whether the input contains any blocked words or phrases.

```swift
if textIsOK(dialog) {
    nextUtterance = dialog
    isGenerating = false
} else {
    nextUtterance = character.errorResponse
    isGenerating = false
    resetSession(character, startWith: character.resumeConversationLine)
}
```
If the output dialog fails the blocked phrases check, the model may break character or discuss something that’s outside of the game world. To keep the dialog immersive, set nextUtterance to the character’s fixed error response and reset the session.
Generate random encounters
The EncounterEngine creates unique customer encounters using the Generable protocol to generate structured content. Each encounter produces an NPC with a name, coffee order, and visual description.

```swift
@Generable
struct NPC: Equatable {
    let name: String
    let coffeeOrder: String
    let picture: GenerableImage
}
```
The process of generating an NPC uses a LanguageModelSession with a prompt that provide examples of the output format:

```swift
let session = LanguageModelSession {
    """
    A conversation between the Player and a helpful assistant. This is a fantasy 
    RPG game that takes place at Dream Coffee, the beloved coffee shop of the 
    dream realm. Your role is to use your imagination to generate fun game characters.
    """
}
let prompt = """
    Create an NPC customer with a fun personality suitable for the dream realm. Have the customer order
    coffee. Here are some examples to inspire you:
    {name: "Thimblefoot", imageDescription: "A horse with a rainbow mane",
    coffeeOrder: "I would like a coffee that's refreshing and sweet like grass of a summer meadow"}
    {name: "Spiderkid", imageDescription: "A furry spider with a cool baseball cap",
    coffeeOrder: "An iced coffee please, that's as spooky as me!"}
    {name: "Wise Fairy", imageDescription: "A blue glowing fairy that radiates wisdom and sparkles",
    coffeeOrder: "Something simple and plant-based please, that will restore my wise energy."}
    """


```
// Generate the NPC using the custom generable type.

```swift
let npc = try await session.respond(
    to: prompt,
    generating: NPC.self,
```
).content
Each generated NPC includes a GenerableImage that creates a visual representation of the character by using Image Playground. The image generation avoids human-like appearances, focusing instead on fantastical creatures, animals, and objects that fit the dream realm aesthetic. The GenerableImage class shows how to use GenerationSchema to describe the properties and guides of the object. This allows for creating dynamic schemas when all of the details of the generable type isn’t known until runtime.
Use a language model to judge in-game creations
The game uses the on-device model to evaluate player performance through the judgeDrink(drink:) method in the encounter engine. When the player creates a coffee drink for a customer, the model assumes the customer’s persona and provides feedback on whether the drink matches their original order.
The judging system creates a new LanguageModelSession that uses the specific customer’s personality and preferences, and a prompt that provides the drink details for the model to evaluate:

```swift
let session = LanguageModelSession {
    """
    A conversation between a user and a helpful assistant. This is a fantasy RPG 
    game that takes place at Dream Coffee, the beloved coffee shop of the dream 
    realm. Your role is to pretend to be the following customer:
    \(customer.name): \(customer.picture.imageDescription)
    """
}
let prompt = """
    You have just ordered the following drink:
    \(customer.coffeeOrder)
    The barista has just made you this drink:
    \(drink)
    Does this drink match your expectations? Do you like it? You must respond 
    with helpful feedback for the barista. If you like your drink, give it a 
    compliment. If you dislike your drink, politely tell the barista why.
    """
```
return try await session.respond(to: prompt).content
The model then compares the player’s creation against the customer’s original order, providing contextual feedback that’s authentic to the character’s personality. This creates a dynamic evaluation system where the same drink might receive different reactions from different customers based on their unique preferences and personas.
Use tools to personalize game content
For customers that the sample generates, provide the dialog engine with custom tools, like CalendarTool to create more personalized interactions. This allows characters to reference the player’s on-device information, making conversations feel more natural and connected to the player’s actual life.
The CalendarTool integrates with EventKit to access the player’s calendar events, and allows characters to reference real upcoming events that involve the customer’s name if they are an attendee:

```swift
if let customer = character as? GeneratedCustomer {
    newSession = LanguageModelSession(
        tools: [CalendarTool(contactName: customer.displayName)],
        instructions: instructions
    )
}
```
The tool description tells the model what it uses the tool for:
description = """

```swift
    Get an event from the player's calendar with \(contactName). \
    Today is \(Date().formatted(date: .complete, time: .omitted))
    """
```
The sample app also provides a ContactTool that accesses the player’s contacts to find names of people born in specific months. This allows the game to generate a coffee shop customer with names the player is familiar with.

```swift
let session = LanguageModelSession(
    tools: [contactsTool],
    instructions: """
        Use the \(contactsTool.name) tool to get a name for a customer.
        """
```
)

## See Also

Tool calling

Expanding generation with tool calling
Build tools that enable the model to perform tasks that are specific to your use case.

```swift
protocol Tool
```
A tool that a model can call to gather information at runtime or perform side effects.



# Protocol

Tool
A tool that a model can call to gather information at runtime or perform side effects.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
protocol Tool<Arguments, Output> : Sendable
```

## Mentioned in


Generating content and performing tasks with Foundation Models

Categorizing and organizing data with content tags

Expanding generation with tool calling

## Overview

Tool calling gives the model the ability to call your code to incorporate up-to-date information like recent events and data from your app. A tool includes a name and a description that the framework puts in the prompt to let the model decide when and how often to call your tool.
A Tool defines a call(arguments:) method that takes arguments that conforms to ConvertibleFromGeneratedContent, and returns an output of any type that conforms to PromptRepresentable, allowing the model to understand and reason about in subsequent interactions. Typically, Output is a String or any Generable types.

```swift
struct FindContacts: Tool {
    let name = "findContacts"
    let description = "Find a specific number of contacts"


    @Generable
    struct Arguments {
        @Guide(description: "The number of contacts to get", .range(1...10))
        let count: Int
    }


    func call(arguments: Arguments) async throws -> [String] {
        var contacts: [CNContact] = []
        // Fetch a number of contacts using the arguments.
        let formattedContacts = contacts.map {
            "\($0.givenName) \($0.familyName)"
        }
        return formattedContacts
    }
}
```
Tools must conform to Sendable so the framework can run them concurrently. If the model needs to pass the output of one tool as the input to another, it executes back-to-back tool calls.
You control the life cycle of your tool, so you can track the state of it between calls to the model. For example, you might store a list of database records that you don’t want to reuse between tool calls.
Prompting the model with tools contributes to the available context window size. When you provide a tool in your generation request, the framework puts the tool definitions — name, description, parameter information — in the prompt so the model can decide when and how often to call the tool. After calling your tool, the framework returns the tool’s output back to the model for further processing.
To efficiently use tool calling:
- Reduce Guide(description:) descriptions to a short phrase each.
- Limit the number of tools you use to three to five.
- Include a tool only when its necessary for the task you want to perform.
- Run an essential tool before calling the model and integrate the tool’s output in the prompt directly.
If your session exceeds the available context size, it throws LanguageModelSession.GenerationError.exceededContextWindowSize(_:). When you encounter the context window limit, consider breaking up tool calls across new LanguageModelSession instances. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

Invoking a tool

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output
```
A language model will call this method when it wants to leverage this tool.
Required
associatedtype Arguments : ConvertibleFromGeneratedContent
The arguments that this tool should accept.
Required
associatedtype Output : PromptRepresentable
The output that this tool produces for the language model to reason about in subsequent interactions.
Required
Getting the tool properties

```swift
var description: String
```
A natural language description of when and how to use the tool.
Required

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
Required Default implementation provided.

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
Required Default implementation provided.

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.
Required Default implementation provided.

## Relationships

Inherits From
- Sendable
- SendableMetatype

## See Also

Tool calling

Expanding generation with tool calling
Build tools that enable the model to perform tasks that are specific to your use case.

Generate dynamic game content with guided generation and tools
Make gameplay more lively with AI generated dialog and encounters personalized to the player.



## Instance Method

call(arguments:)
A language model will call this method when it wants to leverage this tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output
```
Required

## Mentioned in


Expanding generation with tool calling

## Discussion

If errors are throw in the body of this method, they will be wrapped in a LanguageModelSession.ToolCallError and rethrown at the call site of respond(to:options:).
Note
This method may be invoked concurrently with itself or with other tools.

## See Also

Invoking a tool
associatedtype Arguments : ConvertibleFromGeneratedContent
The arguments that this tool should accept.
Required
associatedtype Output : PromptRepresentable
The output that this tool produces for the language model to reason about in subsequent interactions.
Required


Associated Type
Arguments
The arguments that this tool should accept.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
associatedtype Arguments : ConvertibleFromGeneratedContent
Required

## Mentioned in


Expanding generation with tool calling

## Discussion

Typically arguments are either a Generable type or GeneratedContent.

## See Also

Invoking a tool

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output
```
A language model will call this method when it wants to leverage this tool.
Required
associatedtype Output : PromptRepresentable
The output that this tool produces for the language model to reason about in subsequent interactions.
Required


Associated Type
Output
The output that this tool produces for the language model to reason about in subsequent interactions.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
associatedtype Output : PromptRepresentable
Required

## Discussion

Typically output is either a String or a Generable type.

## See Also

Invoking a tool

```swift
func call(arguments: Self.Arguments) async throws -> Self.Output
```
A language model will call this method when it wants to leverage this tool.
Required
associatedtype Arguments : ConvertibleFromGeneratedContent
The arguments that this tool should accept.
Required



## Instance Property

description
A natural language description of when and how to use the tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var description: String { get }
```
Required

## See Also

Getting the tool properties

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
Required Default implementation provided.

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
Required Default implementation provided.

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.
Required Default implementation provided.



## Instance Property

includesSchemaInInstructions
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var includesSchemaInInstructions: Bool { get }
```
Required Default implementation provided.

## Discussion

The default implementation is true
Note
This should only be false if the model has been trained to have innate knowledge of this tool. For zero-shot prompting, it should always be true.

## Default Implementations

Tool Implementations

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

## See Also

Getting the tool properties

```swift
var description: String
```
A natural language description of when and how to use the tool.
Required

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
Required Default implementation provided.

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.
Required Default implementation provided.



## Instance Property

name
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var name: String { get }
```
Required Default implementation provided.

## Default Implementations

Tool Implementations

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.

## See Also

Getting the tool properties

```swift
var description: String
```
A natural language description of when and how to use the tool.
Required

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
Required Default implementation provided.

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.
Required Default implementation provided.



## Instance Property

parameters
A schema for the parameters this tool accepts.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
var parameters: GenerationSchema { get }
```
Required Default implementation provided.

## Default Implementations

Tool Implementations

```swift
var parameters: GenerationSchema
```
A schema for the parameters this tool accepts.

## See Also

Getting the tool properties

```swift
var description: String
```
A natural language description of when and how to use the tool.
Required

```swift
var includesSchemaInInstructions: Bool
```
If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
Required Default implementation provided.

```swift
var name: String
```
A unique name for the tool, such as “get_weather”, “toggleDarkMode”, or “search contacts”.
Required Default implementation provided.



# Structure

LanguageModelFeedback
Feedback appropriate for logging or attaching to Feedback Assistant.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct LanguageModelFeedback
```

## Mentioned in


Improving the safety of generative model output

## Overview

LanguageModelFeedback is a namespace with structures for describing feedback in a consistent way. LanguageModelFeedback.Sentiment describes the sentiment of the feedback, while LanguageModelFeedback.Issue offers a standard template for issues.
Given a model session, use logFeedbackAttachment(sentiment:issues:desiredOutput:) to produce structured feedback.

```swift
let session = LanguageModelSession()
let response = try await session.respond(to: "What is the capital of France?")


```
// Create feedback for a problematic response.

```swift
let feedbackData = session.logFeedbackAttachment(
    sentiment: LanguageModelFeedback.Sentiment.negative,
    issues: [
        LanguageModelFeedback.Issue(
            category: .incorrect,
            explanation: "The model provided outdated information"
        )
    ],
    desiredOutput: Transcript.Entry.response(...)
```
)

## Topics

Creating feedback

```swift
struct Issue
```
An issue with the model’s response.

```swift
enum Sentiment
```
A sentiment regarding the model’s response.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data
```
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.



# Structure

LanguageModelFeedback.Issue
An issue with the model’s response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
struct Issue
```

## Topics

Initializing an issue

```swift
init(category: LanguageModelFeedback.Issue.Category, explanation: String?)
```
Creates a new issue

```swift
enum Category
```
Categories for model response issues.

## Relationships


## Conforms To

- Sendable
- SendableMetatype

## See Also

Creating feedback

```swift
enum Sentiment
```
A sentiment regarding the model’s response.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data
```
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.



## Initializer


```swift
init(category:explanation:)
```
Creates a new issue
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
init(
    category: LanguageModelFeedback.Issue.Category,
    explanation: String? = nil
```
)

## Parameters

category
A category for this issue.
explanation
An optional explanation of this issue.

## See Also

Initializing an issue

```swift
enum Category
```
Categories for model response issues.



# Enumeration

LanguageModelFeedback.Issue.Category
Categories for model response issues.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum Category
```

## Topics

Getting the issue category

```swift
case didNotFollowInstructions
```
The model did not follow instructions correctly.

```swift
case incorrect
```
The model provided an incorrect response.

```swift
case stereotypeOrBias
```
The model exhibited bias or perpetuated a stereotype.

```swift
case suggestiveOrSexual
```
The model produces suggestive or sexual material.

```swift
case tooVerbose
```
The response was too verbose.

```swift
case triggeredGuardrailUnexpectedly
```
The model throws a guardrail violation when it shouldn’t.

```swift
case unhelpful
```
The response was not unhelpful.

```swift
case vulgarOrOffensive
```
The model produces vulgar or offensive material.

## Relationships


## Conforms To

- CaseIterable
- Copyable
- Equatable
- Hashable
- Sendable
- SendableMetatype

## See Also

Initializing an issue

```swift
init(category: LanguageModelFeedback.Issue.Category, explanation: String?)
```
Creates a new issue


Case
LanguageModelFeedback.Issue.Category.didNotFollowInstructions
The model did not follow instructions correctly.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case didNotFollowInstructions
```

## Discussion

An instruction issue might be where you asked for a recipe in numbered steps, and the model provided a recipe but didn’t number the steps.

## See Also

Getting the issue category

```swift
case incorrect
```
The model provided an incorrect response.

```swift
case stereotypeOrBias
```
The model exhibited bias or perpetuated a stereotype.

```swift
case suggestiveOrSexual
```
The model produces suggestive or sexual material.

```swift
case tooVerbose
```
The response was too verbose.

```swift
case triggeredGuardrailUnexpectedly
```
The model throws a guardrail violation when it shouldn’t.

```swift
case unhelpful
```
The response was not unhelpful.

```swift
case vulgarOrOffensive
```
The model produces vulgar or offensive material.


Case
LanguageModelFeedback.Issue.Category.incorrect
The model provided an incorrect response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case incorrect
```

## Discussion

An incorrect issue might be where you asked how to make a pizza, and the model suggested using glue.

## See Also

Getting the issue category

```swift
case didNotFollowInstructions
```
The model did not follow instructions correctly.

```swift
case stereotypeOrBias
```
The model exhibited bias or perpetuated a stereotype.

```swift
case suggestiveOrSexual
```
The model produces suggestive or sexual material.

```swift
case tooVerbose
```
The response was too verbose.

```swift
case triggeredGuardrailUnexpectedly
```
The model throws a guardrail violation when it shouldn’t.

```swift
case unhelpful
```
The response was not unhelpful.

```swift
case vulgarOrOffensive
```
The model produces vulgar or offensive material.


Case
LanguageModelFeedback.Issue.Category.stereotypeOrBias
The model exhibited bias or perpetuated a stereotype.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case stereotypeOrBias
```

## Discussion

A stereotype or bias issue might be where you ask the model to summarize an article written by a male, and the model doesn’t state the authors sex, but the model uses male pronouns.

## See Also

Getting the issue category

```swift
case didNotFollowInstructions
```
The model did not follow instructions correctly.

```swift
case incorrect
```
The model provided an incorrect response.

```swift
case suggestiveOrSexual
```
The model produces suggestive or sexual material.

```swift
case tooVerbose
```
The response was too verbose.

```swift
case triggeredGuardrailUnexpectedly
```
The model throws a guardrail violation when it shouldn’t.

```swift
case unhelpful
```
The response was not unhelpful.

```swift
case vulgarOrOffensive
```
The model produces vulgar or offensive material.


Case
LanguageModelFeedback.Issue.Category.suggestiveOrSexual
The model produces suggestive or sexual material.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case suggestiveOrSexual
```

## Discussion

A suggestive or sexual issue might be where you ask the model to draft a script for a school play, and it includes a sex scene.

## See Also

Getting the issue category

```swift
case didNotFollowInstructions
```
The model did not follow instructions correctly.

```swift
case incorrect
```
The model provided an incorrect response.

```swift
case stereotypeOrBias
```
The model exhibited bias or perpetuated a stereotype.

```swift
case tooVerbose
```
The response was too verbose.

```swift
case triggeredGuardrailUnexpectedly
```
The model throws a guardrail violation when it shouldn’t.

```swift
case unhelpful
```
The response was not unhelpful.

```swift
case vulgarOrOffensive
```
The model produces vulgar or offensive material.


Case
LanguageModelFeedback.Issue.Category.tooVerbose
The response was too verbose.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case tooVerbose
```

## Discussion

A verbose issue might be where you asked for a simple recipe, and the model wrote introductory and conclusion paragraphs.

## See Also

Getting the issue category

```swift
case didNotFollowInstructions
```
The model did not follow instructions correctly.

```swift
case incorrect
```
The model provided an incorrect response.

```swift
case stereotypeOrBias
```
The model exhibited bias or perpetuated a stereotype.

```swift
case suggestiveOrSexual
```
The model produces suggestive or sexual material.

```swift
case triggeredGuardrailUnexpectedly
```
The model throws a guardrail violation when it shouldn’t.

```swift
case unhelpful
```
The response was not unhelpful.

```swift
case vulgarOrOffensive
```
The model produces vulgar or offensive material.


Case
LanguageModelFeedback.Issue.Category.triggeredGuardrailUnexpectedly
The model throws a guardrail violation when it shouldn’t.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case triggeredGuardrailUnexpectedly
```

## Discussion

An unexpected guardrail issue might be where you ask for a cake recipe, and the framework throws a guardrail violation error.

## See Also

Getting the issue category

```swift
case didNotFollowInstructions
```
The model did not follow instructions correctly.

```swift
case incorrect
```
The model provided an incorrect response.

```swift
case stereotypeOrBias
```
The model exhibited bias or perpetuated a stereotype.

```swift
case suggestiveOrSexual
```
The model produces suggestive or sexual material.

```swift
case tooVerbose
```
The response was too verbose.

```swift
case unhelpful
```
The response was not unhelpful.

```swift
case vulgarOrOffensive
```
The model produces vulgar or offensive material.


Case
LanguageModelFeedback.Issue.Category.unhelpful
The response was not unhelpful.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case unhelpful
```

## Discussion

An unhelpful issue might be where you asked for a recipe, and the model gave you a list of ingredients but not amounts.

## See Also

Getting the issue category

```swift
case didNotFollowInstructions
```
The model did not follow instructions correctly.

```swift
case incorrect
```
The model provided an incorrect response.

```swift
case stereotypeOrBias
```
The model exhibited bias or perpetuated a stereotype.

```swift
case suggestiveOrSexual
```
The model produces suggestive or sexual material.

```swift
case tooVerbose
```
The response was too verbose.

```swift
case triggeredGuardrailUnexpectedly
```
The model throws a guardrail violation when it shouldn’t.

```swift
case vulgarOrOffensive
```
The model produces vulgar or offensive material.


Case
LanguageModelFeedback.Issue.Category.vulgarOrOffensive
The model produces vulgar or offensive material.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case vulgarOrOffensive
```

## Discussion

A vulgar or offensive issue might be where you ask the model to draft a complaint about poor customer service, and it uses profanity.

## See Also

Getting the issue category

```swift
case didNotFollowInstructions
```
The model did not follow instructions correctly.

```swift
case incorrect
```
The model provided an incorrect response.

```swift
case stereotypeOrBias
```
The model exhibited bias or perpetuated a stereotype.

```swift
case suggestiveOrSexual
```
The model produces suggestive or sexual material.

```swift
case tooVerbose
```
The response was too verbose.

```swift
case triggeredGuardrailUnexpectedly
```
The model throws a guardrail violation when it shouldn’t.

```swift
case unhelpful
```
The response was not unhelpful.



# Enumeration

LanguageModelFeedback.Sentiment
A sentiment regarding the model’s response.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
enum Sentiment
```

## Topics

Getting sentiment

```swift
case negative
```
A negative sentiment

```swift
case neutral
```
A neutral sentiment

```swift
case positive
```
A positive sentiment

## Relationships


## Conforms To

- CaseIterable
- Copyable
- Equatable
- Hashable
- Sendable
- SendableMetatype

## See Also

Creating feedback

```swift
struct Issue
```
An issue with the model’s response.

```swift
func logFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?, issues: [LanguageModelFeedback.Issue], desiredOutput: Transcript.Entry?) -> Data
```
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.


Case
LanguageModelFeedback.Sentiment.negative
A negative sentiment
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case negative
```

## See Also

Getting sentiment

```swift
case neutral
```
A neutral sentiment

```swift
case positive
```
A positive sentiment


Case
LanguageModelFeedback.Sentiment.neutral
A neutral sentiment
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case neutral
```

## See Also

Getting sentiment

```swift
case negative
```
A negative sentiment

```swift
case positive
```
A positive sentiment


Case
LanguageModelFeedback.Sentiment.positive
A positive sentiment
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+

```swift
case positive
```

## See Also

Getting sentiment

```swift
case negative
```
A negative sentiment

```swift
case neutral
```
A neutral sentiment



## Instance Method

logFeedbackAttachment(sentiment:issues:desiredOutput:)
Logs and serializes data that includes session information that you attach when reporting feedback to Apple.
> iOS 26.0+
> iPadOS 26.0+
> Mac Catalyst 26.0+
> macOS 26.0+
> visionOS 26.0+
@discardableResult
final func logFeedbackAttachment(

```swift
    sentiment: LanguageModelFeedback.Sentiment?,
    issues: [LanguageModelFeedback.Issue] = [],
    desiredOutput: Transcript.Entry? = nil
```
) -> Data

## Parameters

sentiment
A LanguageModelFeedback.Sentiment rating about the model’s output (positive, negative, or neutral).
issues
An array of specific LanguageModelFeedback.Issue you identify with the model’s response.
desiredOutput
A Transcript entry showing the output you expect.

## Return Value

A Data object containing the JSON-encoded attachment.

## Mentioned in


Prompting an on-device foundation model

## Discussion

This method creates a structured attachment containing the session’s transcript and additional feedback information you provide. You can save the attachment data to a .json file and attach it when reporting feedback with Feedback Assistant.
If an error occurs during a previous response, the method includes any rejected entries that were rolled back from the transcript in the feedback data.

```swift
let session = LanguageModelSession()
let response = try await session.respond(to: "What is the capital of France?")


```
// Create feedback for a helpful response.

```swift
let helpfulFeedbackData = session.logFeedbackAttachment(sentiment: .positive)


```
// Create feedback for a problematic response.

```swift
let problematicFeedbackData = session.logFeedbackAttachment(
    sentiment: .negative,
    issues: [
        LanguageModelFeedback.Issue(
            category: .incorrect,
            explanation: "The model provided outdated information"
        )
    ],
    desiredOutput: Transcript.Entry.response(...)
```
)
If desiredOutput is a string, use Transcript.Entry.response(_:) to turn your desired output into a Transcript entry:

```swift
let text = Transcript.TextSegment(content: "The capital of France is Paris.")
let segment = Transcript.Segment.text(text)
let response = Transcript.Response(segments: [segment])
let entry = Transcript.Entry.response(response)
```
To create a transcript when desiredOutput is a Generable type:

```swift
let customType = MyCustomType(...) // A generable type.
let structure = Transcript.StructuredSegment(source: String(describing: Foo.self), content: customType.generatedContent)
let segment = Transcript.Segment.structure(structure)
let response = Transcript.Response(segments: [segment])
let entry = Transcript.Entry.response(response)
```
When you submit feedback to Apple, write your feedback to a .json file and include the file as an attachment to Feedback Assistant. You can include multiple feedback attachments in the same file:

```swift
let allFeedback = helpfulFeedbackData + problematicFeedbackData
let url = URL(fileURLWithPath: "path/to/save/feedback.jsonl")
```
try allFeedback.write(to: url)

## See Also

Creating feedback

```swift
struct Issue
```
An issue with the model’s response.

```swift
enum Sentiment
```
A sentiment regarding the model’s response.



