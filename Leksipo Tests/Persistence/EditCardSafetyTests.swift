import Foundation
import SwiftData
import Testing
@testable import English_Words

@Suite("Безопасность редактора карточки")
@MainActor
struct EditCardSafetyTests {
    @Test("До загрузки и после её ошибки сохранение не меняет карточку и связи", arguments: [false, true])
    func blocksIncompleteForm(loadFails: Bool) throws {
        let f = try EditorFixture()
        let vm = f.viewModel
        #expect(!vm.hasChanges)
        vm.editedOrigin = "draft"
        vm.editedTranslated = "черновик"
        if loadFails {
            f.groups.shouldFail = true
            vm.onAppear()
            #expect(vm.errorMessage != nil)
        }

        vm.toggleGroup(f.originalGroup)
        #expect(!vm.hasLoadedGroups)
        #expect(!vm.canSave)
        #expect(!vm.save())
        #expect(vm.selectedGroups.map(\.id) == [f.originalGroup.id])
        #expect(vm.editedOrigin == "draft")
        #expect(vm.editedTranslated == "черновик")
        #expect(!f.repos.container.mainContext.hasChanges)
        let saved = try f.savedCard()
        #expect(saved.originWord == "word")
        #expect(saved.translatedWord == "слово")
        #expect(saved.groups.map(\.id) == [f.originalGroup.id])
    }

    @Test("Повторная ошибка и успешный повтор сохраняют текст, пояснения и исходные связи")
    func retryPreservesDraftAndRelationships() throws {
        let f = try EditorFixture()
        let vm = f.viewModel
        f.groups.shouldFail = true
        vm.onAppear()
        vm.editedOrigin = "new word"
        vm.editedTranslated = "новое слово"
        vm.editedOriginDescription = "new explanation"
        vm.editedTranslatedDescription = "новое пояснение"
        vm.onAppear()
        #expect(vm.errorMessage != nil)
        #expect(!vm.save())

        f.groups.shouldFail = false
        vm.onAppear()
        #expect(f.groups.fetchCount == 3)
        #expect(vm.hasLoadedGroups)
        #expect(vm.errorMessage == nil)
        #expect(vm.selectedGroups.map(\.id) == [f.originalGroup.id])
        #expect(vm.availableGroups.map(\.id) == [f.otherGroup.id])
        #expect(vm.editedOrigin == "new word")
        #expect(vm.editedTranslated == "новое слово")
        #expect(vm.editedOriginDescription == "new explanation")
        #expect(vm.editedTranslatedDescription == "новое пояснение")
        #expect(vm.canSave)
        #expect(vm.save())

        let saved = try f.savedCard()
        #expect(saved.originWord == "new word")
        #expect(saved.translatedWord == "новое слово")
        #expect(saved.originDescription == "new explanation")
        #expect(saved.translatedDescription == "новое пояснение")
        #expect(saved.groups.map(\.id) == [f.originalGroup.id])
        #expect(saved.groups.first?.cards.map(\.id) == [saved.id])
    }

    @Test("Повторный onAppear не перезагружает группы и не сбрасывает выбор")
    func repeatedAppearancePreservesGroupEdits() throws {
        let f = try EditorFixture()
        let vm = f.viewModel
        vm.onAppear()
        #expect(!vm.hasChanges)
        vm.toggleGroup(f.originalGroup)
        vm.toggleGroup(f.otherGroup)
        vm.editedOrigin = "draft"
        f.groups.shouldFail = true
        vm.onAppear()

        #expect(f.groups.fetchCount == 1)
        #expect(vm.errorMessage == nil)
        #expect(vm.selectedGroups.map(\.id) == [f.otherGroup.id])
        #expect(vm.availableGroups.map(\.id) == [f.originalGroup.id])
        #expect(vm.editedOrigin == "draft")
        #expect(vm.hasChanges)
        #expect(vm.save())
        #expect(try f.savedCard().groups.map(\.id) == [f.otherGroup.id])
    }

    @Test("После успешной загрузки можно намеренно убрать все группы")
    func allowsExplicitlyRemovingAllGroups() throws {
        let f = try EditorFixture()
        f.viewModel.onAppear()
        f.viewModel.toggleGroup(f.originalGroup)
        #expect(f.viewModel.selectedGroups.isEmpty)
        #expect(f.viewModel.canSave)
        #expect(f.viewModel.save())
        #expect(try f.savedCard().groups.isEmpty)
    }

    @Test("Успешная загрузка пустого списка групп разрешает сохранение")
    func emptyGroupListIsNotAnError() throws {
        let repos = try TestContainer.makeRepositories()
        let card = try repos.card.create(origin: "word", translated: "слово", groups: [])
        let vm = EditCardViewModel(card: card, cardRepository: repos.card, groupRepository: repos.group)
        vm.onAppear()
        #expect(vm.hasLoadedGroups)
        #expect(vm.selectedGroups.isEmpty)
        #expect(vm.availableGroups.isEmpty)
        #expect(vm.errorMessage == nil)
        #expect(!vm.hasChanges)
        vm.editedOrigin = "new word"
        #expect(vm.canSave)
        #expect(vm.save())
        let saved = try #require(ModelContext(repos.container).fetch(FetchDescriptor<Card>()).first)
        #expect(saved.originWord == "new word")
        #expect(saved.groups.isEmpty)
    }

    @Test("После загрузки сохраняется проверка обязательных полей", arguments: [true, false])
    func emptyWordsStillBlockSaving(emptyOrigin: Bool) throws {
        let f = try EditorFixture()
        f.viewModel.onAppear()
        if emptyOrigin {
            f.viewModel.editedOrigin = " \n "
        } else {
            f.viewModel.editedTranslated = " \n "
        }
        #expect(!f.viewModel.canSave)
        #expect(!f.viewModel.save())
        #expect(!f.repos.container.mainContext.hasChanges)
        #expect(try f.savedCard().groups.map(\.id) == [f.originalGroup.id])
    }
}

@MainActor
private final class EditorFixture {
    let repos: TestContainer.Repositories
    let originalGroup: CardGroup
    let otherGroup: CardGroup
    let groups: FailingEditorGroupRepository
    let viewModel: EditCardViewModel

    init() throws {
        repos = try TestContainer.makeRepositories()
        originalGroup = try repos.group.create(name: "Original")
        otherGroup = try repos.group.create(name: "Other")
        let card = try repos.card.create(origin: "word", translated: "слово", groups: [originalGroup])
        groups = FailingEditorGroupRepository(base: repos.group)
        viewModel = EditCardViewModel(card: card, cardRepository: repos.card, groupRepository: groups)
    }

    func savedCard() throws -> Card {
        let context = ModelContext(repos.container)
        return try #require(context.fetch(FetchDescriptor<Card>()).first)
    }
}

@MainActor
private final class FailingEditorGroupRepository: GroupRepository {
    private let base: GroupRepository
    var shouldFail = false
    private(set) var fetchCount = 0

    init(base: GroupRepository) {
        self.base = base
    }

    func fetchUserGroups() throws -> [CardGroup] {
        fetchCount += 1
        if shouldFail { throw LoadError.injected }
        return try base.fetchUserGroups()
    }

    func fetch(id: UUID) throws -> CardGroup? { try base.fetch(id: id) }
    func userGroupsCount() throws -> Int { try base.userGroupsCount() }
    func create(name: String) throws -> CardGroup { try base.create(name: name) }
    func rename(_ group: CardGroup, to newName: String) throws { try base.rename(group, to: newName) }
    func delete(_ group: CardGroup) throws { try base.delete(group) }
    func addCard(_ card: Card, to group: CardGroup) throws { try base.addCard(card, to: group) }
    func removeCard(_ card: Card, from group: CardGroup) throws { try base.removeCard(card, from: group) }
    func nameExists(_ name: String, excluding groupID: UUID?) throws -> Bool {
        try base.nameExists(name, excluding: groupID)
    }

    private enum LoadError: Error {
        case injected
    }
}
