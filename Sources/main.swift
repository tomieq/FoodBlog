import Foundation
import SQLite

do {
    print("Open \(Volume.path + "storage.db")")
    let db = try Connection(Volume.path + "storage.db")
    let webApp = try WebApp(db: db)
    try webApp.start()
    print("Server started")
    dispatchMain()
} catch {
    print(error)
}
