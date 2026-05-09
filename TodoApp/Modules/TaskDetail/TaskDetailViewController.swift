import UIKit

final class TaskDetailViewController: UIViewController {
    
    var presenter: TaskDetailPresenterProtocol?
    
    // MARK: - UI Elements
    
    private lazy var titleTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 28, weight: .bold)
        tf.textColor = .white
        tf.attributedPlaceholder = NSAttributedString(
            string: "Название задачи",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.3)]
        )
        tf.borderStyle = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private lazy var dateLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = UIColor.white.withAlphaComponent(0.4)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var descTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.textColor = .white
        tv.backgroundColor = .clear
        tv.text = "Описание..."
        tv.textColor = UIColor.white.withAlphaComponent(0.3)
        tv.delegate = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        btn.setImage(image, for: .normal)
        btn.setTitle(" Назад", for: .normal)
        btn.tintColor = .systemYellow
        btn.setTitleColor(.systemYellow, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Сохранить", for: .normal)
        btn.setTitleColor(.systemYellow, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return btn
    }()
    
    private var isEditingDesc = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter?.viewDidLoad()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        dateLabel.text = formatter.string(from: Date())
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(backButton)
        view.addSubview(saveButton)
        view.addSubview(titleTextField)
        view.addSubview(dateLabel)
        view.addSubview(descTextView)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            saveButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            titleTextField.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 24),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            descTextView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            descTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            descTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let title = titleTextField.text ?? ""
        let desc = isEditingDesc ? (descTextView.text ?? "") : ""
        presenter?.didTapSave(title: title, description: desc)
    }
}

// MARK: - TaskDetailViewProtocol

extension TaskDetailViewController: TaskDetailViewProtocol {
    
    func setTask(_ task: TaskEntity?) {
        guard let task = task else {
            saveButton.setTitle("Добавить", for: .normal)
            return
        }
        saveButton.setTitle("Сохранить", for: .normal)
        titleTextField.text = task.title
        dateLabel.text = {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            return formatter.string(from: task.createdAt ?? Date())
        }()
        if let desc = task.desc, !desc.isEmpty {
            descTextView.text = desc
            descTextView.textColor = .white
            isEditingDesc = true
        }
    }
    
    func dismiss() {
        dismiss(animated: true)
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate

extension TaskDetailViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if !isEditingDesc {
            textView.text = ""
            textView.textColor = .white
            isEditingDesc = true
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespaces).isEmpty {
            textView.text = "Описание..."
            textView.textColor = UIColor.white.withAlphaComponent(0.3)
            isEditingDesc = false
        }
    }
}
