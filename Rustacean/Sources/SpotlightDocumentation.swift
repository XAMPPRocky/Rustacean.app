import Foundation
import CoreSpotlight

class SpotlightDocumentation {
    static func generateDocumentationSpotlight() {
        //let fileManager = FileManager.default

        do {
            let resourceKeys : [URLResourceKey] = [.isDirectoryKey]
            let documentsURL = Rustup.documentationDirectory()
            let enumerator = FileManager.default.enumerator(at: documentsURL,
                                    includingPropertiesForKeys: resourceKeys,
                                    options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                print("directoryEnumerator error at \(url): ", error)
                                                                return true
            })!
            
            var items: [CSSearchableItem] = []
            for case let fileURL as URL in enumerator {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                if resourceValues.isDirectory! {
                    continue
                }
                
                let path = fileURL.absoluteString.dropFirst(documentsURL.absoluteString.count)
                print(String(path))
                items.append(createDocumentationItem(title: String(path)))
            }
            
            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error = error {
                    print("Indexing error: \(error.localizedDescription)")
                } else {
                    print("Search item successfully indexed!")
                }
            }
        } catch {
            print(error)
        }
    }
    
    static func createDocumentationItem(title: String) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeHTML as String)
        attributeSet.title = title
        attributeSet.contentDescription = title

        return CSSearchableItem(uniqueIdentifier: "\(title)", domainIdentifier: "com.xampprocky", attributeSet: attributeSet)
    }
}
