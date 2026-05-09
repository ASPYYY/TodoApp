import UIKit

final class TaskCell: UITableViewCell {
    
    static let identifier = "TaskCell"
    var onToggle: (() -> Void)?
    
    // MARK: - UI Elements
    
    private lazy var checkButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 17, weight: .medium)
        lbl.textColor = .white
        lbl.numberOfLines = 1
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var descLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = UIColor.white.withAlphaComponent(0.6)
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var dateLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12)
        lbl.textColor = UIColor.white.withAlphaComponent(0.4)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var textStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, descLabel, dateLabel])
        sv.axis = .vertical
        sv.spacing = 4
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .black
        selectionStyle = .none
        
        contentView.addSubview(checkButton)
        contentView.addSubview(textStack)
        
        NSLayoutConstraint.activate([
            checkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkButton.widthAnchor.constraint(equalToConstant: 28),
            checkButton.heightAnchor.constraint(equalToConstant: 28),
            
            textStack.leadingAnchor.constraint(equalTo: checkButton.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configure
    
    func configure(with task: TaskEntity) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        dateLabel.text = formatter.string(from: task.createdAt ?? Date())
        descLabel.text = task.desc
        
        if task.isCompleted {
            let attrs: [NSAttributedString.Key: Any] = [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.white.withAlphaComponent(0.4)
            ]
            titleLabel.attributedText = NSAttributedString(string: task.title ?? "", attributes: attrs)
            descLabel.textColor = UIColor.white.withAlphaComponent(0.3)
            
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
            checkButton.setImage(image, for: .normal)
            checkButton.tintColor = .systemYellow
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = task.title
            titleLabel.textColor = .white
            descLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            let image = UIImage(systemName: "circle", withConfiguration: config)
            checkButton.setImage(image, for: .normal)
            checkButton.tintColor = UIColor.white.withAlphaComponent(0.4)
        }
    }
    
    // MARK: - Actions
    
    @objc private func toggleTapped() {
        onToggle?()
    }
}
